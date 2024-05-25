require 'httparty'

module ALPB
  class Game
    AJAX_URL = 'http://baseball.pointstreak.com/ajax/trending_ajax.html?action=leaguescoreboard&leagueid=174'
    attr_reader :away, :home, :date, :status
    def initialize(away, home, date, status, score, id)
      @away = away
      @home = home
      @date = date
      @status = status
      @score = score
      @id = id
    end
    def to_h
      {
        away: @away,
        home: @home,
        date: date_string,
        status: @status,
        score: "#{score[:away]}-#{score[:home]}"
      }
    end
    def date_string
      if @date.to_date == Date.today
        @date.strftime('%-I:%M')
      else
        @date.strftime('%-m/%-d')
      end
    end
    def score
      case @status
      when 'scheduled'
        {away: '-', home: '-'}
      when 'final'
        @score
      when 'in progress'
        get_live_score
      end
    end
    def get_live_score
      json = get_json
      {away: json['awayscore'],
       home: json['homescore']}
    end
    def get_json
      r = Game::cached_json
      r['baseball_list'].select { |x| x['gameid'] == @id }.first
    end
    def self.cached_json
      @@last_request ||= Time.now - 30
      if Time.now - @@last_request >= 30
        @@json = HTTParty.get(AJAX_URL)
        @@last_request = Time.now
      end
      @@json
    end
    def inspect
      "Game<#@away/#@home|#{date_string}|#{score[:away]}-#{score[:home]}>"
    end
    def self.from_tr(tr)
      a, d, h = tr.xpath('./td')
      away_team = a.xpath('.//img').first['alt']
      home_team = h.xpath('.//img').first['alt']
      time_str = d.text.gsub(/\s+/, ' ')[/\w+ \d+ \d+:\d{2} [AP]M/]
      time = Time.strptime(time_str, '%b %d %I:%M %P')
      status = d.xpath('./p')[2].text.downcase
      link = d.xpath('.//a').map { |a| a['href'] }.grep(/pointstreak/).first
      id = link[/gameid=(\d+)/, 1]
      away_score, home_score = d.xpath('.//p').last.text.scan(/\d+/).map(&:to_i)
      Game.new(away_team, home_team, time, status,
               {away: away_score, home: home_score}, id)
    end
  end
end
