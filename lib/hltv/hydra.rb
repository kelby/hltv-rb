module Hltv
  class Hydra
    def matches_mapstatsid
      hydra = Typhoeus::Hydra.new
      (28001..99049).times.map do
        hydra.queue(Typhoeus::Request.new("https://www.hltv.org/stats/matches/mapstatsid/#{mapstatsid}/-", headers: headers, followlocation: true))
      end
      hydra.run
    end

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
