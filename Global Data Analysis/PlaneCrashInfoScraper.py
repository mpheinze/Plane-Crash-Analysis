##### -------------------- Web Scraper for scraping PlaneCrashInfo.org -------------------- #####

import requests
from bs4 import BeautifulSoup

## Looping through years
for page in range(1920, 2017):
	
	url = 'http://www.planecrashinfo.com/' + str(page) + '/' + str(page) + '.htm'
	source_code = requests.get(url)
	soup = BeautifulSoup(source_code.text, 'html.parser')
	
	print '---------- ' + str(page) + ' ----------'
	
	## Counting number of crashes per year
	link_count = 0
	for link in soup.findAll('a'):
		link_count += 1
	
	## Looping through crashes per year
	for sub_page in range(1, link_count):
		sub_url = 'http://www.planecrashinfo.com/' + str(page) + '/' + str(page) + '-' + str(sub_page) + '.htm'
		sub_source_code = requests.get(sub_url)
		sub_soup = BeautifulSoup(sub_source_code.text, 'html.parser')
		
		## Looping through information points per crash
		i = 1
		temp_list = []
		for line in sub_soup.findAll('td'):
			start = str(line).index('size=') + 9
			end = str(line).index('</td>') - 7
			if i >= 4 and i <= 26 and i % 2 == 0:
				data_point = str(line)[start:end]
				temp_list.append(data_point)
			i += 1
		
		## Looping items of the temporary data list into a text file
		file_name = 'scraped_data.txt'
		with open(file_name, 'a') as text_file:
			text_file.write(';;'.join(str(i) for i in temp_list))
			text_file.write('\n')
		
		# Printing running status
		pct = (float(sub_page)/link_count) * 100
		print(str("%.2f" % pct) + ' %')
