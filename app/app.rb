# -*- coding: utf-8 -*-
require 'nokogiri'
require 'open-uri'


module YahuokuBusters
  class App < Padrino::Application
    register Padrino::Mailer
    register Padrino::Helpers

    enable :sessions
    enable :inline_templates
    include ERB::Util
    
    get '/' do
      erb :top, locals: {recommended_users: ["no_regret_y", "miyuria0905", "gurei2200", "ryobochi2"] }
    end

    ## user
    post '/user' do
      user = h(params[:user])
      redirect "/user/#{user}"
    end
    get '/user/:user' do
      show_user_auctions(params[:user], 1)
    end
    get '/user/:user/:page' do
      show_user_auctions(params[:user], params[:page].to_i)      
    end

    ## search
    post '/search' do
      show_search_auctions(params[:keyword], 1)
    end

    get '/search' do
      show_search_auctions(params[:keyword], params[:page])
    end

    ## functions
    def show_user_auctions(user, page=1)
      per_page = 20  # per page
      b = (page-1) * per_page + 1  # start
      i = b
      url = "http://sellinglist.auctions.yahoo.co.jp/user/#{h(user)}?n=#{per_page}&b=#{b}"
      doc = Nokogiri::HTML.parse(open(url))

      ar = doc.search("div#list01//.a1//h3//a").map do |elem|
        url = elem.attribute('href').value
        url =~ %r{/([a-z0-9][0-9]+)}
        a_id = $1
        URI.split(url)[2] =~ /page(\d+)/
        server_number = $1
        {number: i, url: url, a_id: a_id, server_number: server_number, title: elem.inner_html}.tap { i = i + 1}
      end

      #doc.search("div#AS-m19/h1.t/em").inner_html =~ /(\d+)/
      doc.search("div.sbox_2/div.pu/select/option").first.inner_html =~ /(\d+)/
      total = $1.to_i
      erb :user, {locals: {user: user, auction_list: ar, total: total, per_page: per_page}}
    end

    def show_search_auctions(keyword, page=1)
      per_page = 20
      b = (page.to_i-1) * per_page + 1
      i = b

      url = "http://auctions.search.yahoo.co.jp/search?p=#{ERB::Util.url_encode(keyword)}&b=#{b}"
      doc = Nokogiri::HTML.parse(open(url))

      ar = doc.search("div.a1wrp").map do |element|
        ## title
        elem = element.search("h3/a")
        title = elem.inner_html
        href = elem.attribute('href').value
        href =~ /page(\d+)\.auctions.yahoo.co.jp/
        server_number = $1
        href =~ %r{auctions\.yahoo\.co\.jp/jp/auction/([a-z0-9][\d]+)}
        a_id = $1
        url = href

        ## user
        elem = element.search("div.a4/p/a")[1]
        href = elem.attribute('href').value
        href =~ %r{auctions\.yahoo\.co\.jp/user/([a-zA-Z0-9\-_]+)}
        user = $1
        {number: i, url: url, a_id: a_id, server_number: server_number, title: title, user: user}.tap {i = i + 1}
      end
      doc.search("p.total").inner_html =~ /(\d+)/
      total = $1.to_i
      erb :search, locals: {keyword: params[:keyword], auction_list: ar, total: total, per_page: per_page}
    end
    
  end  ## class App
end

