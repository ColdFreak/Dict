#!/usr/bin/env python

import sys, os, re, errno
#from html.parser import HTMLParser
import HTMLParser

#from urllib.request import urlopen
import urllib2

import subprocess

# generate random number in exercise mode
from random import randint

class LinksParser(HTMLParser.HTMLParser):
	def __init__(self):
		HTMLParser.HTMLParser.__init__(self)
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

# append the info about the word to file $HOME/Dict/words_file
def add_a_word(word_content):
	with open(words_file, "a") as f:

		# don't forget encode to utf-8 before write		
		f.write(':'.join(word_content).encode('utf-8'))
		f.write('\n')

def find_word_from_file(word):
	with open(words_file, "r+") as f:
		for line in f.readlines():
			if line.startswith(word):
				# 'True means we found the word in file, then return the line
				return True, line
	return False, ""

def wait_for_input():
	try:
		input_str = raw_input('>> ')
		input_str.strip('\t\r\t\n \"')
		input_str = '+'.join(input_str.split())
	except EOFError:
		print "\n"
		sys.exit(0)
	except KeyboardInterrupt:
		print "\n"
		sys.exit(0)
	return input_str


def delete_from_file(word):
	with open(words_file, "r") as f:
		lines = f.readlines()
	with open(words_file, "w") as f:
		for line in lines:
			if not line.startswith(word) and line not in ['\n', '\r\n']:	
				f.write(line)

def download_mp3(audio_url):
	# we have to simulate Mozilla by using a User-agent in our request 
	#to retrieve content from google
	headers = {'User-Agent' : 'Mozilla/5.0' }
	request = urllib2.Request(audio_url, None, headers)
	mp3file = urllib2.urlopen(request)
	with open(mp3_name, 'wb') as output_mp3: 
		output_mp3.write(mp3file.read())

def process_word(word):
	word_is_there = 0
	word_content = []
	real, string = find_word_from_file(word)

	if real:
		word_is_there = 1			
		print '\n',string
		return word_is_there, list(string)
	else:

		# we didn't find the word in the file, so change word_if_there flag
		# from 1 to 0
		word_is_there = 0

		# url to download the word
		word_url = "http://dict.cn/"+ word

		# if word not found in file, retrieve from web page
		# extract pronounciation and find meaning 
		parser = LinksParser()
		f = urllib2.urlopen(word_url)
		html = f.read()
		html = html.decode('UTF-8')
		parser.feed(html)
		parser.close()
	

		word_meanings = re.findall('</span><strong>(.*)</strong></li>',html, re.MULTILINE)

		# if you try to search a non-sense word like 'asdfsdfs', nothing will be in the date list
		try:
			print "\n-->",word
			word_content.append(word)
			print parser.data[0]
			word_content.append(parser.data[0])
		except IndexError:
		
			print ' Not found\n'

			return False, word_content

		for match in word_meanings:
			word_content.append(match)
			print "\n", match.encode('utf-8')
		
		return word_is_there, word_content


def meaning_to_spelling():
	last_index = 0
	with open(words_file) as f:
		lines = f.readlines()

	print '>>>Exercise mode'
	
	this_index = randint(0, len(lines)-1)

	print "---> ",lines[this_index].split(':')[2]


	while True:
		try:
			spelling = raw_input('>>> ')
		except EOFError:
			print "\n"
			return 
		except KeyboardInterrupt:
			print "\n"
			return 
		
		if spelling == lines[this_index].split(':')[0] :
			print " Good Job \(^_^)/\n"
		else:
			print "Too bad >_< \n"
			print "Right spelling --->", lines[this_index].split(':')[0]

		last_index = this_index

		this_index = randint(0, len(lines)-1)

		while last_index == this_index :

			this_index = randint(0, len(lines)-1)

		print "Next word--> ", lines[this_index].split(':')[2]
		
			
		





if __name__ == "__main__":
	
	
	# flag to show wether the word is already in the file 
	word_is_there = 0

	# wait for input, word or action
	input_str = ""

	# directory to store mp3 files
	mp3_dir =os.environ['HOME'] + "/Dict/mp3_dir/"


	# file to store content of a words
	words_file = os.environ['HOME']+"/Dict/words_file"

	# redirect stdout to /dev/null when play the mp3 file
	dev_null = open('/dev/null', 'w')

	# make directory to store mp3 files
	mkdir_p(mp3_dir)

	
	if len(sys.argv) > 1:
		for i in range(1, len(sys.argv)):
			process_word(sys.argv[i])
			
	
	# try to find the word from file first
	while True:
		# flag to show wether the word is already in the file 		
		word_is_there = 0
		# this contains everython about a word
		word_content = []

		input_str = wait_for_input()

		if (input_str == 'e'):
			# exercise mode, spell the word by the meaning
			meaning_to_spelling()

		else:

			# specific name for each mp3 file
			mp3_name = mp3_dir + input_str + ".mp3"

			#url to download the mp3 file
			audio_url = "http://translate.google.com/translate_tts?tl=en&q="+input_str
			

			word_is_there, word_content = process_word(input_str)

			# if this word's audio file is already exists, just play it
			# do not download it again
			if os.path.exists(mp3_name):
				process = subprocess.Popen(['play', mp3_name], stdout=dev_null, stderr=dev_null)
				retcode = process.wait()
			else:
				# download mp3 file to $HOME/mp3.dir
				download_mp3(audio_url)
				# find wait function on the last line
				process = subprocess.Popen(['play', mp3_name], stdout=dev_null, stderr=dev_null)

		
		
			# play mp3 file and redirect stdout to /dev/null then wait process to complete
			try:
				add_word = raw_input('Add this -> ' )
			except EOFError:
				print "\n"
				sys.exit(0)
			except KeyboardInterrupt:
				print "\n"
				sys.exit(0)

			# press just 'enter' will add this word
			if add_word == "":
				if word_is_there == 1:
					pass
				else:
					os.remove(mp3_name)
					print "  OK, forget about it"
			elif add_word == "y":
				if word_is_there == 1:
					print '  Word already there'
				else:
					add_a_word(word_content)
					print "  Great"
			else:
				if word_is_there == 1:
					delete_from_file(input_str)
					os.remove(mp3_name)
				else:
					os.remove(mp3_name)
				print "  OK, forget about it"

			retcode = process.wait()
