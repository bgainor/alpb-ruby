require 'httparty'
require 'nokogiri'
require 'alpb/game'

module ALPB
  class Schedule
    attr_reader :games
    def initialize
      @response = HTTParty.get('https://atlanticleague.com/schedule')
      @html = Nokogiri::HTML(@response.body)
      @games = @html.xpath(
        '//div//table/tbody/tr').map { |tr| ALPB::Game.from_tr(tr) }
    end
    def team_games(team)
      @games.select do |g|
        g.away =~ team || g.home =~ team
      end
    end
  end
end
