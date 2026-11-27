require 'json'
require 'nokogiri'
require 'uri'
require 'addressable/uri'
require 'yaml'
require 'date'

base = 'https://yorve.github.io/secnotes'
repo = File.expand_path('..', __dir__)
root = File.expand_path('../_site', __dir__)
index = JSON.parse(File.read(File.join(root, 'search.json')))
abort 'Empty search index' if index.empty?

def page_at(root, url)
  path = URI::DEFAULT_PARSER.unescape(Addressable::URI.parse(url).path.sub(%r{\A/secnotes/?}, ''))
  file = File.join(root, path)
  file = File.join(file, 'index.html') if File.directory?(file)
  file += '.html' unless File.exist?(file)
  abort "Missing page: #{url}" unless File.file?(file)
  Nokogiri::HTML(File.read(file))
end

def check_local_images(doc, root, label)
  doc.css('img[src]').each do |img|
    src = img['src'].to_s.strip
    next if src.empty? || src.start_with?('http://', 'https://', 'data:')
    rel = URI::DEFAULT_PARSER.unescape(src.sub(%r{\A/secnotes/?}, '').sub(%r{\A/}, ''))
    target = File.join(root, rel)
    abort "Broken local image on #{label}: #{src}" unless File.file?(target)
  end
end

core_urls = [
  '/',
  '/articulos/',
  '/noticias.html',
  '/stats/',
  '/tags/',
  '/empieza-aqui/',
  '/temas/linux/',
  '/temas/windows/',
  '/temas/pentesting-web/',
  '/metasploitable2',
  '/about',
  '/cheatsheet/'
]

core_urls.each do |url|
  doc = page_at(root, base + url)
  abort "Missing title: #{url}" if doc.at_css('title')&.text.to_s.empty?
  abort "Missing description: #{url}" if doc.at_css('meta[name="description"]')&.[]('content').to_s.empty?
  abort "Missing canonical: #{url}" unless doc.at_css('link[rel="canonical"]')&.[]('href').to_s.start_with?(base)
  abort "Missing sharing image: #{url}" unless doc.at_css('meta[property="og:image"]')&.[]('content').to_s.start_with?(base)
  abort "Placeholder GA ID found on #{url}" if doc.to_html.include?('G-XXXXXXXXXX')
  doc.css('script[type="application/ld+json"]').each { |script| JSON.parse(script.text) }
  check_local_images(doc, root, url)
end

# Validate SecNews boletines source files
boletines_dir = File.join(repo, '_boletines')
Dir.children(boletines_dir).sort.each do |entry|
  full = File.join(boletines_dir, entry)
  abort "Unexpected non-markdown file in _boletines: #{entry}" unless entry.end_with?('.md')
  raw = File.read(full)
  match = raw.match(/\A---\s*\n(.*?)\n---/m)
  abort "Missing front matter in _boletines/#{entry}" unless match
  data = YAML.safe_load(match[1], permitted_classes: [Date, Time])
  abort "Missing title in _boletines/#{entry}" if data['title'].to_s.strip.empty?
  stories = data['noticias']
  abort "Empty noticias list in _boletines/#{entry}" unless stories.is_a?(Array) && !stories.empty?
  stories.each_with_index do |story, idx|
    %w[fecha fuente titulo resumen categoria url].each do |field|
      abort "Missing #{field} in _boletines/#{entry}##{idx}" if story[field].to_s.strip.empty?
    end
    abort "Non-HTTPS URL in _boletines/#{entry}##{idx}" unless story['url'].to_s.start_with?('https://')
  end
end

archive = page_at(root, base + '/articulos/')
archive_links = archive.css('.archive-list a').map { |a| a['href'] }
descriptions = []
index.each do |post|
  abort "Article absent from archive: #{post['url']}" unless archive_links.include?(post['url'])
  doc = page_at(root, base + post['url'].delete_prefix('/secnotes'))
  canonical = doc.at_css('link[rel="canonical"]')&.[]('href')
  abort "Incorrect canonical: #{post['url']}" unless canonical == base + post['url'].delete_prefix('/secnotes')
  summary = doc.at_css('meta[name="description"]')&.[]('content').to_s
  abort "Empty article description: #{post['url']}" if summary.strip.empty?
  descriptions << summary
  graphs = doc.css('script[type="application/ld+json"]').flat_map { |script| data = JSON.parse(script.text); data['@graph'] || [data] }
  article = graphs.find { |item| item['@type'] == 'BlogPosting' }
  abort "Missing BlogPosting schema: #{post['url']}" unless article && article['author']['url'] && article['datePublished']
  abort "Missing breadcrumbs: #{post['url']}" unless graphs.any? { |item| item['@type'] == 'BreadcrumbList' }
  abort "Missing sharing links: #{post['url']}" unless doc.at_css('.share-links a[href^="https://www.linkedin.com/"]')
  check_local_images(doc, root, post['url'])
end

abort 'Repeated article descriptions' unless descriptions.uniq.length == descriptions.length
['/temas/linux/', '/temas/windows/', '/temas/pentesting-web/'].each do |url|
  abort "Empty topic: #{url}" if page_at(root, base + url).css('.archive-list a').empty?
end
abort 'Missing social image' unless File.file?(File.join(root, 'assets/img/secnotes-social.png'))
sitemap = Nokogiri::XML(File.read(File.join(root, 'sitemap.xml')))
abort 'Archive missing from sitemap' unless sitemap.to_xml.include?(base + '/articulos/')
puts "Validated #{index.length} articles, SecNews, stats, tags, local images, unique descriptions, structured data, archive, topics and sharing metadata."
