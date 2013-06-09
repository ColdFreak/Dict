#!/usr/bin/env python3

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
	with open(words_file, "a") as f:
		f.write(':'.join(word))
		f.write('\n')

def find_word_from_file(word):
	with open(words_file, "r+") as f:
		for line in f.readlines():
			if line.startswith(word):
				return True, line
		return False, None

def wait_for_input():
	try:
		input_str = input('>> ')
	except EOFError:
		print ("\n")
		sys.exit(0)
	except KeyboardInterrupt:
		print ("\n")
		sys.exit(0)
	return input_str


def delete_from_file(word):
	with open(words_file, "r") as f:
		lines = f.readlines()
	with open(words_file, "w") as f:
		for line in lines:
			if not line.startswith(word) or line not in ['\n', '\r\n']:			
				f.write(line)

if __name__ == "__main__":
	
	# flag to show wether the word is already in the file 
	word_is_there = 0
	
	# wait for input, word or action
	input_str = ""

	# directory to store mp3 file 
	mp3_dir =os.environ['HOME'] + "/Dict/mp3_dir/"


	# file to store content of a words
	words_file = os.environ['HOME']+"/Dict/words_file"

		# redirect stdout to /dev/null when play the mp3 file
	dev_null = open('/dev/null', 'w')

	# make directory to store mp3 files
	mkdir_p(mp3_dir)


	# try to find the word from file first
	while True:
		# this contains everython about a word, for example "vim:[vɪm]:精力；生气；精神"
		word_content = []
		input_str = wait_for_input()
		# specific name for each mp3 file
		mp3_name = mp3_dir + input_str + ".mp3"
		#url to download the mp3 file
		audio_url = "http://tts.yeshj.com/uk/s/"+input_str

		real, string = find_word_from_file(input_str)
		if real:
			word_is_there = 1			
			print ('\n',string)
		else:

			# we didn't find the word in the file, so change word_if_there flag
			# from 1 to 0
			word_is_there = 0

			# url to download the word
			word_url = "http://dict.cn/"+input_str

			# if word not found in file, retrieve from web page
			# extract pronounciation and find meaning 
			parser = LinksParser()
			f = urlopen(word_url)
			html = f.read()
			html = html.decode('UTF-8')
			parser.feed(html)
			parser.close()
		

			word_meanings = re.findall('</span><strong>(.*)</strong></li>',html, re.MULTILINE)

			# if you try to search a non-sense word like 'asdfsdfs', nothing will be in the date list
			try:
				print ("\n",input_str, parser.data[0])
				word_content.append(input_str)
				word_content.append(parser.data[0])
			except IndexError:
			
				print ('Word not found\n')
				continue

			for match in word_meanings:
				word_content.append(match)
				print ("\n", match)

	# if this word's audio file is already exists, just play it
	# do not download it again
		if os.path.exists(mp3_name):
			process = subprocess.Popen(['play', mp3_name], stdout=dev_null, stderr=dev_null)
			retcode = process.wait()
		else:
			# download mp3 file to $HOME/words_mp3
			mp3file = urlopen(audio_url)
			output_mp3 = open(mp3_name, 'wb')
			output_mp3.write(mp3file.read())
			output_mp3.close()
			process = subprocess.Popen(['play', mp3_name], stdout=dev_null, stderr=dev_null)

	
	
		# play mp3 file and redirect stdout to /dev/null then wait process to complete
		try:
			add_word = input("> Add this? ")
		except EOFError:
			print ("\n")
			sys.exit(0)
		except KeyboardInterrupt:
			print ("\n")
			sys.exit(0)

		# press just 'enter' will add this word
		if add_word == "":
			if word_is_there == 1:
				pass
			else:
				os.remove(mp3_name)
				print ("         OK, forget about it")
		elif add_word == "y":
			if word_is_there == 1:
				print ('  Word already there')
			else:
				add_a_word(word_content)
				print ("  Great")
		else:
			if word_is_there == 1:
				delete_from_file(input_str)
			os.remove(mp3_name)
			print ("  OK, forget about it")

		retcode = process.wait()
