# myapp.rb
require "bundler/setup"

require 'sinatra'
require "./lib/hltv/fetcher"

# Bundler.require

get '/ping' do
  'pong'
end

get '/get_matches' do
  Hltv::Fetcher.new.get_matches.to_json
end

get '/get_match/:id' do
  Hltv::Fetcher.new.get_match(params[:id]).to_json
end

get '/get_event/:id' do
  Hltv::Fetcher.new.get_event(params[:id]).to_json
end

get '/matches_mapstatsid/:mapstatsid' do
  Hltv::Fetcher.new.matches_mapstatsid(params[:mapstatsid]).to_json
end

get '/stats_maps' do
  Hltv::Fetcher.new.stats_maps(params[:event_id], params[:start_date], params[:end_date]).to_json
end

get '/stats_players' do
  Hltv::Fetcher.new.stats_players(params[:player_id], params[:event_id], params[:start_date], params[:end_date]).to_json
end

get '/stats_teams' do
  Hltv::Fetcher.new.stats_teams(params[:team_id], params[:start_date], params[:end_date]).to_json
end

get '/stats_teams_maps' do
  Hltv::Fetcher.new.stats_teams_maps(params[:team_id], params[:start_date], params[:end_date]).to_json
end
