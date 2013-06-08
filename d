#!/usr/bin/python3

import sys, os, re, errno
from html.parser import HTMLParser
from urllib.request import urlopen
import subprocess

class LinksParser(HTMLParser):
	def __init__(self):
		HTMLParser.__init__(self)
		self.recording = 0
		self.data = []

	def handle_starttag(self, tag, attributes):
		if tag != 'bdo':
			return
		if self.recording:
			self.recording += 1
			return
#		for name, value in attributes:
#			if name == 'class' and value == 'phonetic':
#				break
#			else:
#				return
		self.recording = 1

	def handle_endtag(self, tag):
		if tag == 'bdo' and self.recording:
			self.recording -= 1

	def handle_data(self, data):
		if self.recording:
			self.data.append(data)


def mkdir_p(path):
	try:
		os.makedirs(path)
	except OSError as exc: # Python > 2.5
		if exc.errno == errno.EEXIST and os.path.isdir(path):
			pass
		else:
		 	raise

def add_a_word(word):
	file = open(os.environ['HOME']+"/Dict/word_content", "a")
	file.write(':'.join(word))
	file.write('\n')
	file.close()

def find_word_in_file(word):
	f = open(os.environ['HOME']+"/Dict/word_content", "r")
	for line in f.readlines():
		if line.startswith(word):
			return True, line
	return False, None



if __name__ == "__main__":
	# this contains everython about a word, for example "vim:[vɪm]:精力；生气；精神"
	word_content = []
	# url to download the word
	word_url = "http://dict.cn/"+sys.argv[1]

	#url to download the mp3 file
	audio_url = "http://tts.yeshj.com/uk/s/"+sys.argv[1]

	# redirect stdout to /dev/null when play the mp3 file
	dev_null = open('/dev/null', 'w')

	# make directory to store mp3 files
	words_dir =os.environ['HOME']+"/Dict/words_mp3/"
	mkdir_p(words_dir)
	mp3_name = words_dir+sys.argv[1]+".mp3"


	real, string = find_word_in_file(sys.argv[1])
	if real:
		print ('\n',string)
	else:
		# extract pronounciation 
		parser = LinksParser()
		f = urlopen(word_url)
		html = f.read()
		html = html.decode('UTF-8')
		parser.feed(html)

		word_meanings = re.findall('</span><strong>(.*)</strong></li>',html, re.MULTILINE)

	# if this word's audio file is already exists, just play it
	# do not download it again
	if os.path.exists(mp3_name):
		process = subprocess.Popen(['play', mp3_name], stdout=dev_null, stderr=dev_null)
		retcode = process.wait()
		sys.exit(0)
	else:
		# download mp3 file to $HOME/words_mp3
		mp3file = urlopen(audio_url)
		output_mp3 = open(mp3_name, 'wb')
		output_mp3.write(mp3file.read())
		output_mp3.close()
		process = subprocess.Popen(['play', mp3_name], stdout=dev_null, stderr=dev_null)
		retcode = process.wait()

	
	

	# if you try to search a non-sense word like 'asdfsdfs', nothing will be in the date list
	try:
		print (sys.argv[1], parser.data[0])
		word_content.append(sys.argv[1])
		word_content.append(parser.data[0])
	except IndexError:
		sys.exit(0)

	for match in word_meanings:
		word_content.append(match)
		print (match)

	# play mp3 file and redirect stdout to /dev/null then wait process to complete

	try:
		add_word = input("Add this? ")
	except EOFError:
		print ("\n")
		sys.exit(0)
	except KeyboardInterrupt:
		print ("\n")
		sys.exit(0)

	# press just 'enter' will add this word
	if add_word == "":
		os.remove(mp3_name)
		print ("OK, forget about it")
		sys.exit(0)
	if add_word == "y":
		add_a_word(word_content)
		print ("Great")
		sys.exit(0)
	else:
		os.remove(mp3_name)
		print ("OK, forget about it")
		sys.exit(0)

	parser.close()
