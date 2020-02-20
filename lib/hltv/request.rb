require 'typhoeus'
require 'nokogiri'

require 'pry'

module Hltv
  class Request
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
      request = Typhoeus.get("https://www.hltv.org/matches/#{id}/-")

      doc = Nokogiri::HTML(request.body)
    end

    # 从13268开始有地图详情
    # 28001-99049
    def matches_mapstatsid(mapstatsid, body="")
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

    def stats_players(player_id=nil, start_date=nil, end_date=nil)
      start_date = Time.at(start_date.to_i).strftime("%F") if !start_date.nil?
      end_date = Time.at(end_date.to_i).strftime("%F") if !end_date.nil?

      if player_id.nil?
        request = Typhoeus.get "https://www.hltv.org/stats/players", params: {startDate: start_date, endDate: end_date}, headers: headers
      else
        request = Typhoeus.get "https://www.hltv.org/stats/players/#{player_id}/-", params: {startDate: start_date, endDate: end_date}, headers: headers
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
      team_name = summary_ele.css(".SummaryTeamname").text.strip
      team_id = summary_ele.css(".SummaryTeamname a").attr("href").value.split('/')[3].to_i
      # team = {id: team_id, name: team_name}

      rating, dpr, kast, impact, adr, kpr = summary_ele.css(".summaryStatBreakdownDataValue").map &:text
      summary = {nickname: nickname, realname: realname, team_id: team_id, team_name: team_name, rating: rating, dpr: dpr, kast: kast, impact: impact, adr: adr, kpr: kpr}

      # ------------------------------

      stats_eles = doc.css(".statistics .stats-row")

      total_kills = stats_eles[0].css("span").last.text
      headshot = stats_eles[1].css("span").last.text
      total_deaths = stats_eles[2].css("span").last.text
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

      stats = {total_kills: total_kills, headshot: headshot, total_deaths: total_deaths, kd_ratio: kd_ratio, damage_round: damage_round, grenade_dmg_round: grenade_dmg_round, maps_played: maps_played, rounds_played: rounds_played, kills_round: kills_round, assists_round: assists_round, deaths_round: deaths_round, saved_by_teammate_round: saved_by_teammate_round, saved_teammates_round: saved_teammates_round, rating: rating}

      {summary: summary, stats: stats}
    end

    private

    def headers
      _headers = {}
      _headers["Authority"] = "www.hltv.org"
      _headers["Cache-Control"] = "max-age=0"
      _headers["Upgrade-Insecure-Requests"] = "1"
      _headers["User-Agent"] = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14_6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/80.0.3987.106 Safari/537.36"
      _headers["Sec-Fetch-Dest"] = "document"
      _headers["Accept"] = "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.9"
      _headers["Sec-Fetch-Site"] = "none"
      _headers["Sec-Fetch-Mode"] = "navigate"
      _headers["Sec-Fetch-User"] = "?1"
      _headers["Accept-Language"] = "zh-CN,zh;q=0.9,en;q=0.8,pt;q=0.7,zh-TW;q=0.6,fr;q=0.5,ru;q=0.4,ja;q=0.3,es;q=0.2"
      _headers["Cookie"] = "_ga=GA1.2.808081295.1539914234; MatchFilter={%22active%22:false%2C%22live%22:false%2C%22stars%22:1%2C%22lan%22:false%2C%22teams%22:[]}; __cfduid=d0e30472136868a1443bc538fdb43f5701571500671; _gid=GA1.2.1544633397.1581413155; statsTablePadding=small; cf_clearance=c6a98493976373aa1fd1a06b5e6c85c62bbc9f06-1581902558-0-150"
      _headers
    end
  end
end
