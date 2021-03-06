require 'typhoeus'
require 'nokogiri'

require 'pry'

module Hltv
  class Fetcher
    def get_matches
      request = Typhoeus.get("https://www.hltv.org/matches")

      doc = Nokogiri::HTML(request.body)

      live_matches = doc.css(".live-matches .live-match")

      results = []

      live_matches.map do |item|
        id = item.css("a.a-reset").attr("href").value.split('/')[2].to_i

        team1_ele = item.css(".teams img").first
        team2_ele = item.css(".teams img").last

        team1 = {id: team1_ele.attr("src").split('/').last.to_i, name: team1_ele.attr("title")}
        team2 = {id: team2_ele.attr("src").split('/').last.to_i, name: team2_ele.attr("title")}

        format = item.css(".bestof").text.scan(/\d+/)[0].to_i

        event = {id: item.css(".event-logo").attr("src").value.scan(/\d+/)[0].to_i, name: item.css(".event-logo").attr("title").value}
        live = true

        results << {id: id, team1: team1, team2: team2, format: format, event: event, live: live}
      end

      upcoming_matches = doc.css(".upcoming-matches .upcoming-match")

      upcoming_matches.map do |item|
        id = item.css("a.a-reset").attr("href").value.split('/')[2].to_i

        team1_ele = item.css(".team-cell img").first
        team2_ele = item.css(".team-cell img").last

        next if team1_ele.nil? || team2_ele.nil?

        team1 = {id: team1_ele.attr("src").split('/').last.to_i, name: team1_ele.attr("title")}
        team2 = {id: team2_ele.attr("src").split('/').last.to_i, name: team2_ele.attr("title")}

        format = item.css(".map-text").text.scan(/\d+/)[0].to_i

        event = {id: item.css(".event-logo").attr("src").value.scan(/\d+/)[0].to_i, name: item.css(".event-logo").attr("title").value}
        live = false

        results << {id: id, team1: team1, team2: team2, format: format, event: event, live: live}
      end

      results
    end

    def get_match(id)
      request = Typhoeus.get("https://www.hltv.org/matches/#{id}/-", headers: headers)

      if request.success?
          # hell yeah
      elsif request.timed_out?
        # aw hell no
        # log("got a time out")
        return
      elsif request.code == 0
        # Could not get an http response, something's wrong.
        # log(response.return_message)
        return
      else
        # Received a non-successful http response.
        # log("HTTP request failed: " + response.code.to_s)
        return
      end

      doc = Nokogiri::HTML(request.body)
    end

    def get_event(event_id)
      request = Typhoeus.get("https://www.hltv.org/events/#{event_id}/-", headers: headers)

      if request.success?
          # hell yeah
      elsif request.timed_out?
        # aw hell no
        # log("got a time out")
        return
      elsif request.code == 0
        # Could not get an http response, something's wrong.
        # log(response.return_message)
        return
      else
        # Received a non-successful http response.
        # log("HTTP request failed: " + response.code.to_s)
        return
      end

      doc = Nokogiri::HTML(request.body)

      # id = doc.css(".event-header-component.event-holder").css("a").attr("href").value.split('/')[2].to_i
      event_name = doc.css(".eventname").text
      start_date, end_date = doc.css("tbody tr .eventdate").css("span").map{|x| x.attr("data-unix") }.compact.map{|x| x.to_i / 1000}
      prize_pool = doc.css("tbody tr .prizepool").text
      teams_number = doc.css("tbody tr .teamsNumber").text
      country = doc.css("tbody tr .location").css("img").attr("title").value
      location = doc.css("tbody tr .location").text.strip

      # rounds共几列，ordinal当前第几列，id第几列第几行，winner哪个队获胜。几列、几行、几队
      # from从哪列哪行，to到哪列哪行，hit具体到哪列哪行的上下位，type为什么，inNewTier待定来源。几条连线
      brackets = doc.css(".bracket").map{|x| JSON.parse x.attr("data-bracket-json") }

      prize_distribution = doc.css(".placements .col .placement").map do |item|
        placement = item.css("div")[1].text
        prize = item.css("div")[2].text

        {placement: placement, prize: prize}
      end

      teams = doc.css(".teams-attending .team-name").map do |item|
        id = item.css("a").attr("href").value.split('/')[2].to_i
        name = item.css(".text").text

        {id: id, name: name}
      end

      {id: event_id, name: event_name, start_date: start_date, end_date: end_date, prize_pool: prize_pool, teams_number: teams_number, country: country, location: location,
        brackets: brackets, prize_distribution: prize_distribution, teams: teams}
    end

    def get_team(team_id)
      request = Typhoeus.get("https://www.hltv.org/team/#{team_id}/-", headers: headers)

      if request.success?
          # hell yeah
      elsif request.timed_out?
        # aw hell no
        # log("got a time out")
        return
      elsif request.code == 0
        # Could not get an http response, something's wrong.
        # log(response.return_message)
        return
      else
        # Received a non-successful http response.
        # log("HTTP request failed: " + response.code.to_s)
        return
      end

      doc = Nokogiri::HTML(request.body)

      profile_team_ele = doc.css(".profile-team-container")
      id = profile_team_ele.css(".teamlogo").attr("src").value.split("/").last.to_i
      country = profile_team_ele.css(".team-country img").attr("title").value
      name = profile_team_ele.css(".profile-team-name").text
      # --------------------------------

      stat_ele = doc.css(".profile-team-stats-container")
      world_ranking = stat_ele.css(".profile-team-stat .right")[0].text.scan(/\d+/)[0].to_i
      weeks_in_top30_for_core = stat_ele.css(".profile-team-stat .right")[1].text
      average_player_age = stat_ele.css(".profile-team-stat .right")[2].text

      stat = {world_ranking: world_ranking, weeks_in_top30_for_core: weeks_in_top30_for_core, average_player_age: average_player_age}
      # --------------------------------
    end

    # ==============================================

    def stats_players(player_id=nil, event_id=nil, start_date=nil, end_date=nil)
      start_date = Time.at(start_date.to_i).strftime("%F") if !start_date.nil?
      end_date = Time.at(end_date.to_i).strftime("%F") if !end_date.nil?

      if player_id.nil?
        request = Typhoeus.get "https://www.hltv.org/stats/players", params: {startDate: start_date, endDate: end_date}, headers: headers
      else
        request = Typhoeus.get "https://www.hltv.org/stats/players/#{player_id}/-", params: {event: event_id, startDate: start_date, endDate: end_date}, headers: headers
      end

      if request.success?
          # hell yeah
      elsif request.timed_out?
        # aw hell no
        # log("got a time out")
        return
      elsif request.code == 0
        # Could not get an http response, something's wrong.
        # log(response.return_message)
        return
      else
        # Received a non-successful http response.
        # log("HTTP request failed: " + response.code.to_s)
        return
      end

      doc = Nokogiri::HTML(request.body)

      summary_ele = doc.css(".playerSummaryStatBox")

      nickname = summary_ele.css(".summaryNickname").text
      realname = summary_ele.css(".summaryRealname").text.strip
      country = summary_ele.css(".summaryRealname img").attr("title").value
      team_name = summary_ele.css(".SummaryTeamname").text.strip
      team_id = summary_ele.css(".SummaryTeamname a").attr("href").value.split('/')[3].to_i
      # team = {id: team_id, name: team_name}

      rating, dpr, kast, impact, adr, kpr = summary_ele.css(".summaryStatBreakdownDataValue").map &:text
      summary = {nickname: nickname, realname: realname, country: country, team_id: team_id, team_name: team_name, rating: rating, dpr: dpr, kast: kast, impact: impact, adr: adr, kpr: kpr}

      # ------------------------------

      stats_eles = doc.css(".statistics .stats-row")

      total_kills = stats_eles[0].css("span").last.text.to_i
      headshot = stats_eles[1].css("span").last.text
      total_deaths = stats_eles[2].css("span").last.text.to_i
      kd_ratio = stats_eles[3].css("span").last.text
      damage_round = stats_eles[4].css("span").last.text
      grenade_dmg_round = stats_eles[5].css("span").last.text
      maps_played = stats_eles[6].css("span").last.text
      rounds_played = stats_eles[7].css("span").last.text
      kills_round = stats_eles[8].css("span").last.text
      assists_round = stats_eles[9].css("span").last.text
      deaths_round = stats_eles[10].css("span").last.text
      saved_by_teammate_round = stats_eles[11].css("span").last.text
      saved_teammates_round = stats_eles[12].css("span").last.text
      rating = stats_eles[13].css("span").last.text

      stats = {total_kills: total_kills, headshot: headshot, total_deaths: total_deaths, kd_ratio: kd_ratio, damage_round: damage_round, grenade_dmg_round: grenade_dmg_round, maps_played: maps_played, rounds_played: rounds_played, kills_round: kills_round, assists_round: assists_round, deaths_round: deaths_round, saved_by_teammate_round: saved_by_teammate_round, saved_teammates_round: saved_teammates_round, rating: rating, kill_death_difference: total_kills - total_deaths}

      {summary: summary, stats: stats}
    end

    def stats_teams(team_id=nil, start_date=nil, end_date=nil)
      start_date = Time.at(start_date.to_i).strftime("%F") if !start_date.nil?
      end_date = Time.at(end_date.to_i).strftime("%F") if !end_date.nil?

      if team_id.nil?
        request = Typhoeus.get "https://www.hltv.org/stats/teams", params: {startDate: start_date, endDate: end_date}, headers: headers
      else
        request = Typhoeus.get "https://www.hltv.org/stats/teams/#{team_id}/-", params: {startDate: start_date, endDate: end_date}, headers: headers
      end

      if request.success?
          # hell yeah
      elsif request.timed_out?
        # aw hell no
        # log("got a time out")
        return
      elsif request.code == 0
        # Could not get an http response, something's wrong.
        # log(response.return_message)
        return
      else
        # Received a non-successful http response.
        # log("HTTP request failed: " + response.code.to_s)
        return
      end

      doc = Nokogiri::HTML(request.body)

      standard_eles = doc.css(".columns .standard-box")

      maps_played = standard_eles[0].css(".large-strong").text # 比赛场次
      wins_draws_losses = standard_eles[1].css(".large-strong").text.scan(/\d+/).map(&:to_i) # 胜平负
      total_kills = standard_eles[2].css(".large-strong").text # 总击杀
      total_deaths = standard_eles[3].css(".large-strong").text # 总死亡
      rounds_played = standard_eles[4].css(".large-strong").text # 多少回合
      kd_ratio = standard_eles[5].css(".large-strong").text #击杀/死亡比

      {maps_played: maps_played, wins_draws_losses: wins_draws_losses, total_kills: total_kills, total_deaths: total_deaths, rounds_played: rounds_played, kd_ratio: kd_ratio}
    end

    def stats_teams_maps(team_id=nil, start_date=nil, end_date=nil)
      start_date = Time.at(start_date.to_i).strftime("%F") if !start_date.nil?
      end_date = Time.at(end_date.to_i).strftime("%F") if !end_date.nil?

      if team_id.nil?
        request = Typhoeus.get "https://www.hltv.org/stats/teams/maps", params: {startDate: start_date, endDate: end_date}, headers: headers
      else
        request = Typhoeus.get "https://www.hltv.org/stats/teams/maps/#{team_id}/-", params: {startDate: start_date, endDate: end_date}, headers: headers
      end

      if request.success?
          # hell yeah
      elsif request.timed_out?
        # aw hell no
        # log("got a time out")
        return
      elsif request.code == 0
        # Could not get an http response, something's wrong.
        # log(response.return_message)
        return
      else
        # Received a non-successful http response.
        # log("HTTP request failed: " + response.code.to_s)
        return
      end

      doc = Nokogiri::HTML(request.body)

      map_breakdown_data = JSON.parse doc.css(".graph").attr("data-fusionchart-config").text
      map_breakdown = map_breakdown_data["dataSource"]["data"].map{|x| x.slice(*["label", "value"])}

      map_highlight = doc.css(".map-pool .map-stats .map-pool-map-name").map do |x|
        map = x.text. split("-").first.strip
        highlight = x.text. split("-").last.strip

        {label: map, value: highlight}
      end

      maps = doc.css(".two-grid .col .map-pool").map do |item|
        item.css(".map-pool-map-name").text
      end

      overviews = doc.css(".two-grid .col .stats-rows").map do |item|
        wins_draws_losses = item.css(".stats-row")[0].css("span").last.text.scan(/\d+/).map(&:to_i)
        win_rate = item.css(".stats-row")[1].css("span").last.text
        total_rounds = item.css(".stats-row")[2].css("span").last.text
        round_win_after_getting_first_kill = item.css(".stats-row")[3].css("span").last.text
        round_win_after_receiving_first_death = item.css(".stats-row")[4].css("span").last.text

        {
          wins_draws_losses: wins_draws_losses,
          win_rate: win_rate,
          total_rounds: total_rounds,
          round_win_after_getting_first_kill: round_win_after_getting_first_kill,
          round_win_after_receiving_first_death: round_win_after_receiving_first_death,
        }
      end

      map_overview = {map: maps, overview: overviews}

      {map_breakdown: map_breakdown, map_highlight: map_highlight, map_overview: map_overview}
    end

    def stats_matches(id=nil)
      request = Typhoeus.get("https://www.hltv.org/stats/matches/#{id}/-", headers: headers)

      if request.success?
          # hell yeah
      elsif request.timed_out?
        # aw hell no
        # log("got a time out")
        return
      elsif request.code == 0
        # Could not get an http response, something's wrong.
        # log(response.return_message)
        return
      else
        # Received a non-successful http response.
        # log("HTTP request failed: " + response.code.to_s)
        return
      end

      doc = Nokogiri::HTML(request.body)

      match_info_ele = doc.css(".match-info-box")

      team1_ele = match_info_ele.css(".team-left")
      team1 = {id: team1_ele.css('img').attr('src').value.split('/').last.to_i, name: team1_ele.css('img').attr('title').value, score: team1_ele.css('div').last.text.to_i}

      team2_ele = match_info_ele.css(".team-right")
      team2 = {id: team2_ele.css('img').attr('src').value.split('/').last.to_i, name: team2_ele.css('img').attr('title').value, score: team2_ele.css('div').last.text.to_i}

      event = {id: match_info_ele.css("a").first.attr("href").split("event=").last.to_i, name: match_info_ele.css("a").first.text}

      date = match_info_ele.css(".small-text span").first.attr("data-unix")

      row_eles = doc.css(".match-info-row")

      team_rating = {team1: row_eles[0].css('.right').text.split(" : ").first, team2: row_eles[0].css('.right').text.split(" : ").last}
      first_kills = {team1: row_eles[1].css('.right').text.scan(/\d+/).first.to_i, team2: row_eles[1].css('.right').text.scan(/\d+/).last.to_i}
      clutches_won = {team1: row_eles[2].css('.right').text.scan(/\d+/).first.to_i, team2: row_eles[2].css('.right').text.scan(/\d+/).last.to_i}

      players_eles = doc.css(".top-players .most-x-box")

      most_kills = {id: players_eles[0].css(".name a").first.attr('href').split('/')[-2].to_i, name: players_eles[0].css(".name a").first.text, value: players_eles[0].css(".value .valueName").text}
      most_damage = {id: players_eles[1].css(".name a").first.attr('href').split('/')[-2].to_i, name: players_eles[1].css(".name a").first.text, value: players_eles[1].css(".value .valueName").text}
      most_assists = {id: players_eles[2].css(".name a").first.attr('href').split('/')[-2].to_i, name: players_eles[2].css(".name a").first.text, value: players_eles[2].css(".value .valueName").text}
      most_awp_kills = {id: players_eles[3].css(".name a").first.attr('href').split('/')[-2].to_i, name: players_eles[3].css(".name a").first.text, value: players_eles[3].css(".value .valueName").text}
      most_first_kills = {id: players_eles[4].css(".name a").first.attr('href').split('/')[-2].to_i, name: players_eles[4].css(".name a").first.text, value: players_eles[4].css(".value .valueName").text}
      best_rating = {id: players_eles[5].css(".name a").first.attr('href').split('/')[-2].to_i, name: players_eles[5].css(".name a").first.text, value: players_eles[5].css(".value .valueName").text}

      overview = {team_rating: team_rating, first_kills: first_kills, clutches_won: clutches_won, most_kills: most_kills, most_damage: most_damage, most_assists: most_assists, most_awp_kills: most_awp_kills, most_first_kills: most_first_kills, best_rating: best_rating}

      stats_eles = doc.css(".stats-table tbody")

      player_stats = {}

      team1_stats_ele = stats_eles.first
      team1_stats = []
      team1_stats_ele.css("tr").map do |item|
        player = {id: item.css('.st-player a').first.attr("href").split('/')[-2].to_i, name: item.css('.st-player a').first.text}
        kills = item.css('.st-kills').text.scan(/\d+/).first.to_i
        hs_kills = item.css('.st-kills').text.scan(/\d+/).last.to_i
        assists = item.css('.st-assists').text.scan(/\d+/).first.to_i
        flash_assists = item.css('.st-assists').text.scan(/\d+/).last.to_i
        deaths = item.css('.st-deaths').text.to_i
        kast = item.css('.st-kdratio').text
        kill_deaths_difference = item.css('.st-kddiff').text
        adr = item.css('.st-adr').text
        first_kills_difference = item.css('.st-fkdiff').text
        rating = item.css('.st-rating').text

        team1_stats << {player: player, kills: kills, hs_kills: hs_kills, assists: assists, flash_assists: flash_assists, deaths: deaths, kast: kast, kill_deaths_difference: kill_deaths_difference, adr: adr, first_kills_difference: first_kills_difference, rating: rating}
      end
      player_stats['team1'] = team1_stats

      team2_stats_ele = stats_eles.last
      team2_stats = []
      team2_stats_ele.css("tr").map do |item|
        player = {id: item.css('.st-player a').first.attr("href").split('/')[-2].to_i, name: item.css('.st-player a').first.text}
        kills = item.css('.st-kills').text.scan(/\d+/).first.to_i
        hs_kills = item.css('.st-kills').text.scan(/\d+/).last.to_i
        assists = item.css('.st-assists').text.scan(/\d+/).first.to_i
        flash_assists = item.css('.st-assists').text.scan(/\d+/).last.to_i
        deaths = item.css('.st-deaths').text.to_i
        kast = item.css('.st-kdratio').text
        kill_deaths_difference = item.css('.st-kddiff').text
        adr = item.css('.st-adr').text
        first_kills_difference = item.css('.st-fkdiff').text
        rating = item.css('.st-rating').text

        team2_stats << {player: player, kills: kills, hs_kills: hs_kills, assists: assists, flash_assists: flash_assists, deaths: deaths, kast: kast, kill_deaths_difference: kill_deaths_difference, adr: adr, first_kills_difference: first_kills_difference, rating: rating}
      end
      player_stats['team2'] = team2_stats

      performance_data = JSON.parse doc.css(".graph").attr("data-fusionchart-config").value
      performance_rating = performance_data["dataSource"]["data"].map{|x| x.slice(*["label", "value"])}

      {date: date, team1: team1, team2: team2, event: event, overview: overview, player_stats: player_stats, performance_rating: performance_rating}
    end

    def stats_events
    end

    def stats_maps(event_id=nil, start_date=nil, end_date=nil)
      start_date = Time.at(start_date.to_i).strftime("%F") if !start_date.nil?
      end_date = Time.at(end_date.to_i).strftime("%F") if !end_date.nil?

      if event_id.nil?
        request = Typhoeus.get "https://www.hltv.org/stats/maps", params: {startDate: start_date, endDate: end_date}, headers: headers
      else
        request = Typhoeus.get "https://www.hltv.org/stats/maps", params: {event: event_id, startDate: start_date, endDate: end_date}, headers: headers
      end

      if request.success?
          # hell yeah
      elsif request.timed_out?
        # aw hell no
        # log("got a time out")
        return
      elsif request.code == 0
        # Could not get an http response, something's wrong.
        # log(response.return_message)
        return
      else
        # Received a non-successful http response.
        # log("HTTP request failed: " + response.code.to_s)
        return
      end

      doc = Nokogiri::HTML(request.body)

      maps_played_data = JSON.parse doc.css(".graph")[0].attr("data-fusionchart-config")
      maps_played = maps_played_data["dataSource"]["data"].map{|k| k.slice(*["label", "value"]) }
      maps_count = maps_played.map{|k| k["value"].to_i }.inject(&:+)

      # --------------------------------

      wins_on_maps_data = JSON.parse doc.css(".graph")[1].attr("data-fusionchart-config")

      wins_on_maps_data["dataSource"]["categories"]
      wins_on_maps_data["dataSource"]["categories"][0]["category"]
      wins_on_maps_data["dataSource"]["categories"][0]["category"].map{|k| k["label"] }

      wins_on_maps_data["dataSource"]["dataset"]
      ct = wins_on_maps_data["dataSource"]["dataset"][0]
      wins_on_maps_ct = ct["data"].map{|k| k["value"] }

      terrorist = wins_on_maps_data["dataSource"]["dataset"][1]
      wins_on_maps_terrorist = terrorist["data"].map{|k| k["value"] }

      wins_on_maps = {ct: wins_on_maps_ct, terrorist: wins_on_maps_terrorist}

      {maps_played: maps_played, wins_on_maps: wins_on_maps, maps_count: maps_count}
    end

    def stats_leaderboards
    end

    def stats_compare
    end

    # ==============================================

    # 从13268开始有地图详情
    # 28001-99049
    def stats_matches_mapstatsid(mapstatsid, body="")
      if body.empty?
        request = Typhoeus.get "https://www.hltv.org/stats/matches/mapstatsid/#{mapstatsid}/-", headers: headers

        if request.success?
            # hell yeah
        elsif request.timed_out?
          # aw hell no
          # log("got a time out")
          return
        elsif request.code == 0
          # Could not get an http response, something's wrong.
          # log(response.return_message)
          return
        else
          # Received a non-successful http response.
          # log("HTTP request failed: " + response.code.to_s)
          return
        end

        doc = Nokogiri::HTML(request.body)
      else
        doc = Nokogiri::HTML(body)
      end

      # puts request.code
      items = doc.css(".round-history-con .round-history-team-row")

      # ----------------------
      item_first = items.first
      team1_ele = item_first.css("img.round-history-team")
      team1 = {id: team1_ele.attr("src").value.scan(/\d+/)[0].to_i, name: team1_ele.attr("title").value}

      team1_firstHalf_ele = item_first.css(".round-history-half").first
      team1_firstHalf = []
      team1_firstHalf_ele.css(".round-history-outcome").each_with_index do |round_ele, index|
        current_round = index + 1
        result = round_ele.attr("src").split(/\.|\//)[-2]
        title = round_ele.attr("title")

        team1_firstHalf << {current_round: current_round, result: result, title: title}
      end

      team1_secondHalf_ele = item_first.css(".round-history-half").last
      team1_secondHalf = []
      team1_secondHalf_ele.css(".round-history-outcome").each_with_index do |round_ele, index|
        current_round = index + 1
        result = round_ele.attr("src").split(/\.|\//)[-2]
        title = round_ele.attr("title")

        team1_secondHalf << {current_round: current_round, result: result, title: title}
      end

      # ----------------------

      item_last = items.last
      team2_ele = item_last.css("img.round-history-team")
      team2 = {id: team2_ele.attr("src").value.scan(/\d+/)[0].to_i, name: team2_ele.attr("title").value}

      team2_firstHalf_ele = item_last.css(".round-history-half").first
      team2_firstHalf = []
      team2_firstHalf_ele.css(".round-history-outcome").each_with_index do |round_ele, index|
        current_round = index + 1
        result = round_ele.attr("src").split(/\.|\//)[-2]
        title = round_ele.attr("title")

        team2_firstHalf << {current_round: current_round, result: result, title: title}
      end

      team2_secondHalf_ele = item_last.css(".round-history-half").last
      team2_secondHalf = []
      team2_secondHalf_ele.css(".round-history-outcome").each_with_index do |round_ele, index|
        current_round = index + 1
        result = round_ele.attr("src").split(/\.|\//)[-2]
        title = round_ele.attr("title")

        team2_secondHalf << {current_round: current_round, result: result, title: title}
      end

      # ----------------------

      match_info_ele = doc.css(".match-info-box-con .match-info-box")

      event_id = match_info_ele.css("a")[0].attr("href").scan(/\d+/)[0].to_i
      event_name = match_info_ele.css("a")[0].text

      # ----------------------
      breakdown_ele = doc.css(".match-info-box-con .match-info-row")[0]
      breakdowns = breakdown_ele.css(".right").text.scan(/\d+/).map(&:to_i)
      t_won = breakdowns[0]
      t_lost = breakdowns[1]
      t_firstHalf_won = breakdowns[2]
      t_firstHalf_lost = breakdowns[3]
      t_secondHalf_won = breakdowns[4]
      t_secondHalf_lost = breakdowns[5]
      t_overtime_won = breakdowns[6]
      t_overtime_lost = breakdowns[7]

      if t_overtime_won.nil? && t_overtime_lost.nil?
        overtime = {}
      else
        overtime = {won: t_overtime_won, lost: t_overtime_lost}
      end
      breakdown = {won: t_won, lost: t_lost, firstHalf: {won: t_firstHalf_won, lost: t_firstHalf_lost}, secondHalf: {won: t_secondHalf_won, lost: t_secondHalf_lost}, overtime: overtime}

      # ----------------------
      match_ele = doc.css(".match-info-box-con a.match-page-link")
      match_id = match_ele.attr("href").value.split("/")[2].to_i
      # ----------------------

      stats_eles = doc.css(".stats-table")

      team1_stats_ele = stats_eles.first
      team1_stats = []
      team1_stats_ele.css("tbody tr").map do |player_tr_ele|
        player_ele  = player_tr_ele.css("td")[0]
        player = {id: player_ele.css("a").attr("/")[-2].to_i, name: player_ele.css("a").text}

        kills_ele   = player_tr_ele.css("td")[1]
        kills = kills_ele.text

        assists_ele = player_tr_ele.css("td")[2]
        assists = assists_ele.text

        deaths_ele  = player_tr_ele.css("td")[3]
        deaths = deaths_ele.text

        kdratio_ele = player_tr_ele.css("td")[4]
        kdratio = kdratio_ele.text

        kddiff_ele  = player_tr_ele.css("td")[5]
        kddiff = kddiff_ele.text

        adr_ele     = player_tr_ele.css("td")[6]
        adr = adr_ele.text

        fkdiff_ele  = player_tr_ele.css("td")[7]
        fkdiff = fkdiff_ele.text

        rating_ele  = player_tr_ele.css("td")[8]
        rating = rating_ele.text

        team1_stats << {player: player, kills: kills, assists: assists, deaths: deaths, kdratio: kdratio, kddiff: kddiff, adr: adr, fkdiff: fkdiff, rating: rating}
      end

      # ----------------------

      team2_stats_ele = stats_eles.last
      team2_stats = []
      team2_stats_ele.css("tbody tr").map do |player_tr_ele|
        player_ele  = player_tr_ele.css("td")[0]
        player = {id: player_ele.css("a").attr("/")[-2].to_i, name: player_ele.css("a").text}

        kills_ele   = player_tr_ele.css("td")[1]
        kills = kills_ele.text

        assists_ele = player_tr_ele.css("td")[2]
        assists = assists_ele.text

        deaths_ele  = player_tr_ele.css("td")[3]
        deaths = deaths_ele.text

        kdratio_ele = player_tr_ele.css("td")[4]
        kdratio = kdratio_ele.text

        kddiff_ele  = player_tr_ele.css("td")[5]
        kddiff = kddiff_ele.text

        adr_ele     = player_tr_ele.css("td")[6]
        adr = adr_ele.text

        fkdiff_ele  = player_tr_ele.css("td")[7]
        fkdiff = fkdiff_ele.text

        rating_ele  = player_tr_ele.css("td")[8]
        rating = rating_ele.text

        team2_stats << {player: player, kills: kills, assists: assists, deaths: deaths, kdratio: kdratio, kddiff: kddiff, adr: adr, fkdiff: fkdiff, rating: rating}
      end

      # ----------------------

      {team_stats: {team1: team1_stats, team2: team2_stats}, event: {id: event_id, name: event_name}, match_id: match_id, team1: team1, team1_firstHalf: team1_firstHalf, team1_secondHalf: team1_secondHalf, team2: team2, team2_firstHalf: team2_firstHalf, team2_secondHalf: team2_secondHalf, breakdown: breakdown}
    end

    private

    def headers
      _headers = {}

      _headers["Authority"] = "www.hltv.org"
      _headers["Upgrade-Insecure-Requests"] = "1"
      _headers["User-Agent"] = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14_6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/80.0.3987.116 Safari/537.36"
      _headers["Sec-Fetch-Dest"] = "document"
      _headers["Accept"] = "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.9"
      _headers["Sec-Fetch-Site"] = "none"
      _headers["Sec-Fetch-Mode"] = "navigate"
      _headers["Sec-Fetch-User"] = "?1"
      _headers["Accept-Language"] = "zh-CN,zh;q=0.9,en;q=0.8,pt;q=0.7,zh-TW;q=0.6,fr;q=0.5,ru;q=0.4,ja;q=0.3,es;q=0.2"
      _headers["Cookie"] = "_ga=GA1.2.808081295.1539914234; MatchFilter={%22active%22:false%2C%22live%22:false%2C%22stars%22:1%2C%22lan%22:false%2C%22teams%22:[]}; __cfduid=d0e30472136868a1443bc538fdb43f5701571500671; statsTablePadding=small; _gid=GA1.2.1867843134.1582457537; cf_clearance=b28297f5494e597750b22f278b2890a044f1061f-1582586100-0-150"

      _headers
    end
  end
end
