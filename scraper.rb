require 'HTTParty'
require 'Nokogiri'


def get_markdown_file(counter, title, author, drummer, directions_list)
  file_contents = "---\nlayout: entry\npermalink: /#{counter}/\ntitle: #{title}\nauthor: #{author}\ndrummer:\n"
  drummer.each do |drummer|
    file_contents += "  - #{drummer}\n"
  end
  file_contents += "steps:\n"
  directions_list.each do |step|
    file_contents += "  - #{step}\n"
  end
  file_contents += "---\n"
  file_contents
end

base_url = "https://www.jazzdisco.org/cti-records/"
url_suffix = ['a-m-records-catalog-2000-3000-series', 'catalog-1000-series', 'catalog-6000-series', 'catalog-5000-series', 'catalog-7000-series', 'catalog-8000-series', 'catalog-9000-series', 'kudu-records-catalog-twelve-inch-series']
stored_pages = []

for suffix in url_suffix
  # Get the page
  page = HTTParty.get(base_url + suffix)
  # store the page
  parsed_page = Nokogiri::HTML(page)
  # put the page in array
  stored_pages.append(parsed_page)
end

page_counter = 1
drummer_names = []
new_albums = []

for page in stored_pages
  # define the content to get (which is found in the css class catalog-data and <p> tag)
  paragraphs = page.css('#catalog-data p')
  # define the parts of the content to discard (reject) (do to end is block - discards anything where this evaluates to true)
  lists = paragraphs.reject do |paragraph|
    # .content gets the string (a nokogiri object), and .index(';') looks for the first instance of the ;
    paragraph.content.index(';').nil?
  end
  for personnel_string in lists
    # took out of paragraph form and converted it to an array of strings
    players = personnel_string.content.split(';')
    for player in players
      if player.include?('drums')
        comma_index = player.index(',')
        player_name = player[0...comma_index]
        drummer_names.push(player_name)
      end
    end
  end

  albums = page.css('#catalog-data a')
  albums.to_a.each do |album|
    new_albums.push(album.content)
  end

end

drummer_hash = Hash.new
for drummer in drummer_names
  drummer_hash[drummer] = []
end

for album in new_albums
  space_index = album.index( /\d / )+1
  album_search = album[space_index..-1]
  album_search = 'https://www.google.com/search?q='+ album_search.b.gsub(' ', '+')
  google_search_page = HTTParty.get(album_search)
  parsed_google_search_page = Nokogiri::HTML(google_search_page)
  parsed_google_search_page.css('a').to_a.each do |link|
    wikipedia_link = link['href'] if link['href'].include?('wikipedia')
    break
  end
  next if wikipedia_link.nil?
  wikipedia_page = HTTParty.get(wikipedia_link)
  parsed_wikipedia_page = Nokogiri::HTML(wikipedia_page)
  drummer = ''
  list_elements = parsed_wikipedia_page.css('li')
  for element in list_elements
    if element.include?('drums')
      hyphen_index = element.index(' -')
      drummer_name = element[0...hyphen_index]
      drummer_hash[drummer_name].push(album)
      break
    end
  end

end

puts drummer_hash