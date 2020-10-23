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

for page in stored_pages
  paragraphs = page.css('#catalog-data p')
  lists = paragraphs.reject do |paragraph|
    paragraph.content.index(';').nil?
  end
  for personnel_string in lists
    players = personnel_string.content.split(';')
    for player in players
      if player.include?('drums')
        comma_index = player.index(',')
        drummer_names.push(player[0...comma_index])
      end
    end
  end

  for page in stored_pages
    albums = page.css('#catalog-data a')
    album_titles = albums.reject do |album|
      album.content.index(';').nil?
  end

end

puts drummer_names.uniq