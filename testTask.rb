require 'curb'
require 'nokogiri'
require 'csv'

def GetProductLinks(url)
  result = []
  xpathToProductLink = '//div[@class="product-container"]/div/div/a/@href'
  page = 1;
  html = nil;

  loop do
    targetUrl = GenerateUrl(url, page)

    if(page == 1)
      html = GetHtml(url)
    else
      html = GetHtml(targetUrl)
    end

    puts "Page №#{page}"

    links = html.xpath(xpathToProductLink)
    puts (links.size.to_s + " link on that page")
    links.each do |link|
      result.push(link)
    end

    page += 1
    break if (links.size == 0)
  end
  return result
end

def GenerateUrl (url, index)
  return (url + "?p=#{index}")
end

def GetHtml (url)
  http = Curl.get(url) do |http|
    http.ssl_verify_peer = false
  end
  body = Nokogiri::HTML(http.body)
  return body
end

def GetProduct(url)
  begin
    product = Hash[]
    html = GetHtml(url)

    title = html.xpath('//h1/text()').first.content.strip.capitalize
    product['title'] = title
    attributesWeight = []
    attributesPrice = []

    html.xpath('//div[@class="attribute_list"]/ul/li/label/span[@class="radio_label"]').each do |attribute|
      attributesWeight.push(attribute.content)
    end
    html.xpath('//div[@class="attribute_list"]/ul/li/label/span[@class="price_comb"]').each do |attribute|
      attributesPrice.push(attribute.content)
    end

    variations = Hash[]
    while attributesWeight.length > 0
      price = attributesPrice.pop
      weight = attributesWeight.pop

      variations[weight] = [price]
    end

    product['variations'] = variations
    imgUrl = html.xpath('//img[@id="bigpic"]/@src').first.content
    product["img"] = imgUrl

    return product
  rescue
    puts "Ther's a problem with #{url}"
  end
end

def WriteProduct (file, product)
  product['variations'].to_a.each do |variation|
    item = []
    title = "#{product['title']} - #{variation[0]}"
    price = variation[1][0].sub(",", ".").to_f
    img = product["img"]

    newItem =  item.push(title, price, img)
    WriteCsv(file, newItem)
  end
end

def WriteCsv(file, item)
  csvObject = CSV.open(file, "ab") do |csv|
    csv << item
  end
end

def Main(url, file)
  puts "Script started"
  productLinks = GetProductLinks(url)
  wroteProducts = 0

  productLinks.each do |link|
    begin
      product = GetProduct(link)
      puts "Get Product - success"
      WriteProduct(file, product)
      puts "Write Product - success"

      wroteProducts += 1
      puts "Wrote #{wroteProducts} / #{productLinks.length}"
    end
  end
  puts "Finished"
end

url = ARGV[0]
file = ARGV[1]

Main(url, file)
