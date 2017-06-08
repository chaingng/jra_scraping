#! ruby
# -*- mode:ruby; coding:utf-8 -*-

require 'site_prism'
require 'capybara/rspec'
require 'selenium-webdriver'
require 'pry'

Capybara.register_driver :chrome do |app|
  Capybara::Selenium::Driver.new(
    app,
    browser: :chrome
  )
end

Capybara.current_driver = :chrome
Capybara.app_host = 'http://www.jra.go.jp/'


class Home < SitePrism::Page
  set_url '/'
  element :race_result_link, '#q_menu6 > a > img'

  element :search_link, 'body > table > tbody > tr > td > table:nth-child(8) > tbody > tr > td > table:nth-child(3) > tbody > tr:nth-child(2) > td > div > font > a'

  element :year, '#kaisaiY_list'
  element :month, '#kaisaiM_list'
  element :search_year_month_button, 'body > table > tbody > tr > td > table:nth-child(8) > tbody > tr > td > table:nth-child(3) > tbody > tr > td:nth-child(2) > a > img'

  elements :day_tables, 'table.contentsGridBase > tbody > tr:nth-child(3) > td table.kaisaiDay1'

  element :first_race_button, 'body > table > tbody > tr > td > table:nth-child(8) > tbody > tr > td > table.contentsGridBase > tbody > tr:nth-child(3) > td > div:nth-child(5) > table > tbody > tr > td:nth-child(2) > table > tbody > tr > td:nth-child(2) > a'
  element :first_race_ozz_button, 'body > table > tbody > tr > td > table:nth-child(8) > tbody > tr > td > table:nth-child(2) > tbody > tr > td > table.raceList > tbody > tr:nth-child(3) > td:nth-child(7) > a > img'

  element :sanrenpuku_button, '#wrapper > div.oddslistArea > div > table > tbody > tr > td:nth-child(11) > a'
  element :popularity_desc_button, '#wrapper > div.ozUmaNinkiBtnTable > table > tbody > tr > td.Btn.unBtn > a'
  element :kaisai_button, '#wrapper > div.oddsKaisaiArea > div > table > tbody > tr', text: '阪神', match: :prefer_exact

  elements :race_buttons, '#wrapper > div.raceSelectTopArea > div > table > tbody > tr > td'
  elements :kaisai_buttons, '#wrapper > div.oddsKaisaiArea > div > table > tbody > tr > td > a'

  element :race_title, '#wrapper > div.raceTtlTable > table > tbody > tr:nth-child(1) > td.cTtl.headerOdds'
  element :race_number, '#wrapper > div.raceNMTable > table > tbody > tr'

  elements :sources, '#wrapper > div:nth-child(15) > div.ozNinkiOutTable > table > tbody > tr'

  element :ozz_link, '#q_menu4 > a > img'
  element :now_sat_kaisai_table, '#inner > table > tbody > tr > td.mainArea > div:nth-child(3) > table'
  element :now_sun_kaisai_table, '#inner > table > tbody > tr > td.mainArea > div:nth-child(4) > table'

  element :now_sanrenpuku_button, '#wrapper > div.raceList2Area > table > tbody > tr:nth-child(3) > td:nth-child(9) > a > img'
end

def scraping_search(year, month)
  @home = Home.new
  @home.load
  @home.race_result_link.click
  @home.search_link.click

  @home.year.find('option', text: year).select_option
  @home.month.find('option', text: month).select_option
  @home.search_year_month_button.click

  day_nums = @home.day_tables
  for index in 0...day_nums.length do
    scrape_3renpuku(year, month, index)
  end
end

def scrape_3renpuku(year, month, kaisai_num)
  @home = Home.new
  @home.load
  @home.race_result_link.click
  @home.search_link.click

  @home.year.find('option', text: year).select_option
  @home.month.find('option', text: month).select_option
  @home.search_year_month_button.click

  cur_date = @home.day_tables[kaisai_num].find('tbody > tr > th[width="130"]').text
  day = cur_date[cur_date.index('月')+1..-5].to_i
  day = format("%02d", day)

  @home.day_tables[kaisai_num].find('tbody > tr > td:nth-child(2) > table > tbody > tr > td:nth-child(2) > a').click

  @home.first_race_ozz_button.click

  @home.sanrenpuku_button.click
  #@home.popularity_desc_button.click

  @home.wait_for_kaisai_buttons
  @home.wait_until_kaisai_buttons_visible
  kaisai_buttons = @home.kaisai_buttons

  for i in 0...kaisai_buttons.length do
    @home.wait_for_kaisai_buttons
    @home.wait_until_kaisai_buttons_visible
    @home.kaisai_buttons[i].click

    @home.wait_for_race_buttons
    @home.wait_until_race_buttons_visible
    race_buttons = @home.race_buttons
    for j in 0...race_buttons.length do
      @home.wait_for_race_buttons
      @home.wait_until_race_buttons_visible
      @home.race_buttons[j].click

      @home.wait_for_race_title
      @home.wait_for_race_number

      puts @home.race_title.text
      puts @home.race_number.text
      # @home.wait_for_race_title
      kaisai =
        case @home.race_title.text
        when /^.*阪神.*$/
          'hanshin'
        when /^.*中山.*$/
          'nakayama'
        when /^.*京都.*$/
          'kyoto'
        when /^.*東京.*$/
          'tokyo'
        when /^.*新潟.*$/
          'niigata'
        when /^.*小倉.*$/
          'kokura'
        when /^.*札幌.*$/
          'sapporo'
        when /^.*福島.*$/
          'fukushima'
        when /^.*中京.*$/
          'chukyo'
        else
          'others'
        end

      # @home.wait_for_race_number
      race_num =
        case @home.race_number.text
        when /^.*11R.*$/
          '11'
        when /^.*12R.*$/
          '12'
        when /^.*1R.*$/
          '01'
        when /^.*2R.*$/
          '02'
        when /^.*3R.*$/
          '03'
        when /^.*4R.*$/
          '04'
        when /^.*5R.*$/
          '05'
        when /^.*6R.*$/
          '06'
        when /^.*7R.*$/
          '07'
        when /^.*8R.*$/
          '08'
        when /^.*9R.*$/
          '09'
        when /^.*10R.*$/
          '10'
        else
          'others'
        end

      lines = @home.text.split(' ')
      lines = lines.drop_while {|t| t!='1-2'}
      lines = lines.take_while {|t| t!='発売票数' }
      lines.select!{|t| (t=~ /^.*[0-9]$/ || t == '取消') }

      i = 0
      file_name =  "#{year}#{month}#{day}-#{kaisai}-#{race_num}.3fuku"
      File.open('../jupyter/data/'+file_name, "w") do |f|
        while i < lines.size do
          # if lines[i].nil?
          #   break
          # end
          #
          if lines[i].include?('-')
            one = lines[i].split('-')[0]
            two = lines[i].split('-')[1]
            i += 1
          end

          if lines[i+1].nil?
            break
          end

          if lines[i+1].include?('-')
            one = lines[i+1].split('-')[0]
            two = lines[i+1].split('-')[1]
            i += 2
            next
            # if i >= lines.size
            #   break
            # end
          end

          three = lines[i]
          ozz = lines[i+1]
          i += 2
          f.puts("#{one} #{two} #{three} #{ozz}") if ozz != '取消'
        end
      end
    end
  end
end


def scrape_3renpuku_now(year, month, sat: true)
  @home = Home.new
  @home.load
  @home.ozz_link.click

  if sat
    cur_date = @home.now_sat_kaisai_table.find('tbody > tr > th').text
    day = cur_date[cur_date.index('月')+1..-5].to_i
    day = format("%02d", day)

    @home.now_sat_kaisai_table.find('tbody > tr > td > table > tbody > tr > td:nth-child(1) > a').click
  else
    cur_date = @home.now_sun_kaisai_table.find('tbody > tr > th').text
    day = cur_date[cur_date.index('月')+1..-5].to_i
    day = format("%02d", day)

    @home.now_sun_kaisai_table.find('tbody > tr > td > table > tbody > tr > td:nth-child(1) > a').click
  end

  @home.now_sanrenpuku_button.click

  @home.wait_for_kaisai_buttons
  @home.wait_until_kaisai_buttons_visible
  kaisai_buttons = @home.kaisai_buttons

  for i in 0...kaisai_buttons.length do
    @home.wait_for_kaisai_buttons
    @home.wait_until_kaisai_buttons_visible
    @home.kaisai_buttons[i].click

    @home.wait_for_race_buttons
    @home.wait_until_race_buttons_visible
    race_buttons = @home.race_buttons
    for j in 0...race_buttons.length do
      @home.wait_for_race_buttons
      @home.wait_until_race_buttons_visible
      @home.race_buttons[j].click

      @home.wait_for_race_title
      @home.wait_for_race_number

      puts @home.race_title.text
      puts @home.race_number.text
      # @home.wait_for_race_title
      kaisai =
        case @home.race_title.text
        when /^.*阪神.*$/
          'hanshin'
        when /^.*中山.*$/
          'nakayama'
        when /^.*京都.*$/
          'kyoto'
        when /^.*東京.*$/
          'tokyo'
        when /^.*新潟.*$/
          'niigata'
        when /^.*小倉.*$/
          'kokura'
        when /^.*札幌.*$/
          'sapporo'
        when /^.*福島.*$/
          'fukushima'
        when /^.*中京.*$/
          'chukyo'
        else
          'others'
        end

      # @home.wait_for_race_number
      race_num =
        case @home.race_number.text
        when /^.*11R.*$/
          '11'
        when /^.*12R.*$/
          '12'
        when /^.*1R.*$/
          '01'
        when /^.*2R.*$/
          '02'
        when /^.*3R.*$/
          '03'
        when /^.*4R.*$/
          '04'
        when /^.*5R.*$/
          '05'
        when /^.*6R.*$/
          '06'
        when /^.*7R.*$/
          '07'
        when /^.*8R.*$/
          '08'
        when /^.*9R.*$/
          '09'
        when /^.*10R.*$/
          '10'
        else
          'others'
        end

      lines = @home.text.split(' ')
      lines = lines.drop_while {|t| t!='1-2'}
      lines = lines.take_while {|t| t!='発売票数' }
      lines.select!{|t| (t=~ /^.*[0-9]$/ || t == '取消') }

      i = 0
      file_name =  "#{year}#{month}#{day}-#{kaisai}-#{race_num}.3fuku"
      File.open('../jupyter/data/'+file_name, "w") do |f|
        while i < lines.size do
          # if lines[i].nil?
          #   break
          # end
          #
          if lines[i].include?('-')
            one = lines[i].split('-')[0]
            two = lines[i].split('-')[1]
            i += 1
          end

          if lines[i+1].nil?
            break
          end

          if lines[i+1].include?('-')
            one = lines[i+1].split('-')[0]
            two = lines[i+1].split('-')[1]
            i += 2
            next
            # if i >= lines.size
            #   break
            # end
          end

          three = lines[i]
          ozz = lines[i+1]
          i += 2
          f.puts("#{one} #{two} #{three} #{ozz}") if ozz != '取消'
        end
      end
    end
  end
end


#scraping_search('2016','11')
#scraping_search('2016','12')
#scraping_search('2016','10')
#scraping_search('2016','09')

#scraping_search('2017','01')
scrape_3renpuku_now('2017','02')
scrape_3renpuku_now('2017','02', sat: false)
