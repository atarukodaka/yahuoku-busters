# -*- coding: utf-8 -*-

module YahuokuBusters
  class App < Padrino::Application
    register Padrino::Mailer
    register Padrino::Helpers

    enable :sessions
    enable :inline_templates
    include ERB::Util
    
    get '/' do
      erb :top, locals: {recommended_users: ["no_regret_y", "miyuria0905", "gurei2200"] }
    end

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

    def show_user_auctions(user, page=1)
      require 'nokogiri'
      require 'open-uri'

      per_page = 20  # per page
      b = (page-1) * per_page + 1  # start
      i = b
      url = "http://sellinglist.auctions.yahoo.co.jp/user/#{h(user)}?n=#{per_page}&b=#{b}"
      doc = Nokogiri::HTML.parse(open(url))

      ar = doc.search("div#list01//.a1//h3//a").map do |elem|
        url = elem.attribute('href').value
        url =~ %r{/([a-z][0-9]+)}
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
  end  ## class App
end
__END__
@@layout

<html>
  <head>
  <title>ヤフオクバスターズ</title>
</head>
  <body>
  <%= yield %>

  <hr/>
  <footer><a href="/">top</a></footer>
  </body>
</html>


@@top

<h2>ヤフオク違反申告支援ツール：ヤフオクバスターズ</h2>

  <% form_tag("/user", method: "post") do %>
ユーザー名<%= text_field_tag(:user, size: 20) %>

   
<%= submit_tag("view") %>
<% end %>

<h2>recommended users to apply for review of violation</h2>

<ul>
<% recommended_users.each do |user| %>
  <li><a href="/user/<%= user %>"><%= user %></a></li>
<% end %>
</ul>

