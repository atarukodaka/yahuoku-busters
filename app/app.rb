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
      require 'nokogiri'
      require 'open-uri'
      
      user = params[:user]

      url = "http://sellinglist.auctions.yahoo.co.jp/user/#{h(user)}"
      doc = Nokogiri::HTML.parse(open(url))
      require 'pry-byebug'
#      binding.pry
      ar = doc.search("div#list01//.a1//h3//a").map do |elem|
        url = elem.attribute('href').value
        url =~ %r{/([a-z][0-9]+)}
        a_id = $1
        URI.split(url)[2] =~ /page(\d+)/
        server_number = $1
        {url: url, a_id: a_id, server_number: server_number, title: elem.inner_html}
      end

      erb :user, {locals: {user: user, auction_list: ar}}
    end
  end
end
__END__
@@layout

<html>
  <head>
  <title>ヤフオクバスターズ</title>
</head>
  <body>
  <%= yield %>
  </body>
</html>


@@top

<h2>user selection</h2>
<% form_tag("/user", method: "post") do %>
User: <%= text_field_tag(:user, size: 20) %>
<%= submit_tag("view") %>
<% end %>

<h2>recommended users to apply for review of violation</h2>

<ul>
<% recommended_users.each do |user| %>
  <li><a href="/user/<%= user %>"><%= user %></a></li>
<% end %>
</ul>

@@user
<h2>user: <%= h(user) %></h2>

<table>
<% auction_list.each do |hash| %>
<tr>
<td><%= hash[:a_id] %>
<td><%= link_to(hash[:title], hash[:url]) %>
<td>
<form method=post action="http://navi<%= hash[:server_number] %>.auctions.yahoo.co.jp/jp/config/review">
  <input type=hidden name=aID value="<%= hash[:a_id] %>">
  <input type=hidden name=rating value="1001">
  <input type=submit value="違反報告">
</form>
</tr>
<% end %>
</table>

