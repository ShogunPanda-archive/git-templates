class UrlsParser
  # To update the list: http:jecas.cz/tld-list/
  TLDS = [
    "ac", "academy", "accountants", "actor", "ad", "ae", "aero", "af", "ag", "agency", "ai", "airforce", "al", "am", "an", "ao", "aq", "ar", "archi", "arpa",
    "as", "asia", "associates", "at", "attorney", "au", "audio", "autos", "aw", "ax", "axa", "az",
    "ba", "bar", "bargains", "bayern", "bb", "bd", "be", "beer", "berlin", "best", "bf", "bg", "bh", "bi", "bid", "bike", "bio", "biz", "bj", "black",
    "blackfriday", "blue", "bm", "bn", "bo", "boutique", "br", "bs", "bt", "build", "builders", "buzz", "bv", "bw", "by", "bz",
    "ca", "cab", "camera", "camp", "capital", "cards", "care", "career", "careers", "cash", "cat", "catering", "cc", "cd", "center", "ceo", "cf", "cg", "ch",
    "cheap", "christmas", "church", "ci", "citic", "ck", "cl", "claims", "cleaning", "clinic", "clothing", "club", "cm", "cn", "co", "codes", "coffee",
    "college", "cologne", "com", "community", "company", "computer", "condos", "construction", "consulting", "contractors", "cooking", "cool", "coop",
    "country", "cr", "credit", "creditcard", "cruises", "cu", "cv", "cw", "cx", "cy", "cz",
    "dance", "dating", "de", "degree", "democrat", "dental", "dentist", "desi", "diamonds", "digital", "directory", "discount", "dj", "dk", "dm", "dnp", "do",
    "domains", "dz",
    "ec", "edu", "education", "ee", "eg", "email", "engineering", "enterprises", "equipment", "er", "es", "estate", "et", "eu", "eus", "events", "exchange",
    "expert", "exposed",
    "fail", "farm", "feedback", "fi", "finance", "financial", "fish", "fishing", "fitness", "fj", "fk", "flights", "florist", "fm", "fo", "foo", "foundation",
    "fr", "frogans", "fund", "furniture", "futbol",
    "ga", "gal", "gallery", "gb", "gd", "ge", "gf", "gg", "gh", "gi", "gift", "gl", "glass", "globo", "gm", "gmo", "gn", "gop", "gov", "gp", "gq", "gr",
    "graphics", "gratis", "gripe", "gs", "gt", "gu", "guide", "guitars", "guru", "gw", "gy",
    "haus", "hiphop", "hiv", "hk", "hm", "hn", "holdings", "holiday", "homes", "horse", "host", "house", "hr", "ht", "hu",
    "id", "ie", "il", "im", "immobilien", "in", "industries", "info", "ink", "institute", "insure", "int", "international", "investments", "io", "iq", "ir",
    "is", "it",
    "je", "jetzt", "jm", "jo", "jobs", "jp", "juegos",
    "kaufen", "ke", "kg", "kh", "ki", "kim", "kitchen", "kiwi", "km", "kn", "koeln", "kp", "kr", "kred", "kw", "ky", "kz",
    "la", "land", "lawyer", "lb", "lc", "lease", "li", "life", "lighting", "limited", "limo", "link", "lk", "loans", "london", "lr", "ls", "lt", "lu", "luxe",
    "luxury", "lv", "ly",
    "ma", "maison", "management", "mango", "market", "marketing", "mc", "md", "me", "media", "meet", "menu", "mg", "mh", "miami", "mil", "mk", "ml", "mm",
    "mn", "mo", "mobi", "moda", "moe", "monash", "mortgage", "moscow", "motorcycles", "mp", "mq", "mr", "ms", "mt", "mu", "museum", "mv", "mw", "mx", "my",
    "mz", "na", "nagoya", "name", "nc", "ne", "net", "neustar", "nf", "ng", "ni", "ninja", "nl", "no", "np", "nr", "nu", "nyc", "nz",
    "okinawa", "om", "onl", "org",
    "pa", "paris", "partners", "parts", "pe", "pf", "pg", "ph", "photo", "photography", "photos", "pics", "pictures", "pink", "pk", "pl", "plumbing", "pm",
    "pn", "post", "pr", "press", "pro", "productions", "properties", "ps", "pt", "pub", "pw", "py",
    "qa", "qpon", "quebec",
    "re", "recipes", "red", "reise", "reisen", "ren", "rentals", "repair", "report", "rest", "reviews", "rich", "rio", "ro", "rocks", "rodeo", "rs", "ru",
    "ruhr", "rw", "ryukyu",
    "sa", "saarland", "sb", "sc", "schule", "sd", "se", "services", "sexy", "sg", "sh", "shiksha", "shoes", "si", "singles", "sj", "sk", "sl", "sm", "sn", "so",
    "social", "software", "sohu", "solar", "solutions", "soy", "space", "sr", "st", "su", "supplies", "supply", "support", "surgery", "sv", "sx", "sy",
    "systems", "sz",
    "tattoo", "tax", "tc", "td", "technology", "tel", "tf", "tg", "th", "tienda", "tips", "tj", "tk", "tl", "tm", "tn", "to", "today", "tokyo", "tools", "town",
    "toys", "tp", "tr", "trade", "training", "travel", "tt", "tv", "tw", "tz",
    "ua", "ug", "uk", "university", "uno", "us", "uy", "uz",
    "va", "vacations", "vc", "ve", "vegas", "ventures", "versicherung", "vet", "vg", "vi", "viajes", "villas", "vision", "vn", "vodka", "vote", "voting",
    "voto", "voyage", "vu",
    "wang", "watch", "webcam", "website", "wed", "wf", "wien", "wiki", "works", "ws", "wtc", "wtf",
    "xn--3bst00m", "xn--3ds443g", "xn--3e0b707e", "xn--45brj9c", "xn--4gbrim", "xn--55qw42g", "xn--55qx5d", "xn--6frz82g", "xn--6qq986b3xl", "xn--80adxhks",
    "xn--80ao21a", "xn--80asehdb", "xn--80aswg", "xn--90a3ac", "xn--c1avg", "xn--cg4bki", "xn--clchc0ea0b2g2a9gcd", "xn--czr694b", "xn--czru2d", "xn--d1acj3b",
    "xn--fiq228c5hs", "xn--fiq64b", "xn--fiqs8s", "xn--fiqz9s", "xn--fpcrj9c3d", "xn--fzc2c9e2c", "xn--gecrj9c", "xn--h2brj9c", "xn--i1b6b1a6a2e", "xn--io0a7i",
    "xn--j1amh", "xn--j6w193g", "xn--kprw13d", "xn--kpry57d", "xn--l1acc", "xn--lgbbat1ad8j", "xn--mgb9awbf", "xn--mgba3a4f16a", "xn--mgbaam7a8h",
    "xn--mgbab2bd", "xn--mgbayh7gpa", "xn--mgbbh1a71e", "xn--mgbc0a9azcg", "xn--mgberp4a5d4ar", "xn--mgbx4cd0ab", "xn--ngbc5azd", "xn--nqv7f",
    "xn--nqv7fs00ema", "xn--o3cw4h", "xn--ogbpf8fl", "xn--p1ai", "xn--pgbs0dh", "xn--q9jyb4c", "xn--rhqv96g", "xn--s9brj9c", "xn--ses554g", "xn--unup4y",
    "xn--wgbh1c", "xn--wgbl6a", "xn--xkc2al3hye2a", "xn--xkc2dl3a5ee0h", "xn--yfro4i67o", "xn--ygbi2ammx", "xn--zfr164b", "xxx", "xyz",
    "yachts", "ye", "yokohama", "yt",
    "za", "zm", "zone", "zw"
  ].freeze

  URL_MATCHER = /
    (
      (http(s?):\/\/)? #PROTOCOL
      (([\w\-\_]+\.)*) # LOWEST TLD
      ([\w\-\_]+) # 2nd LEVEL TLD
      (\.(#{TLDS.join("|")})) # TOP TLD
      ((:\d+)?) # PORT
      ((\/\S*)?) # PATH
      ((\?\S+)?) # QUERY
      ((\#\S*)?) # FRAGMENT
    )
  /ix

  URL_SEPARATOR = /[\[\]!"#$%&'()*+,.:;<=>?~\s@\^_`\{|\}\-]/

  EMAIL_MATCHER = /
    ^(
      ([\w\+\-\_\.\']+@) #HOST
      (([\w\-]+\.)*) # LOWEST TLD
      ([\w\-_]+) # 2nd LEVEL TLD
      (\.(#{TLDS.join("|")})) # TOP TLD
    )$
  /ix

  DOMAIN_MATCHER = /
    ^(
      (([\w\-]+\.)*) # LOWEST TLD
      ([\w\-_]+) # 2nd LEVEL TLD
      (\.(#{TLDS.join("|")})) # TOP TLD
    )$
  /ix

  TEMPLATE = "{{urls.url_%s}}".freeze

  def self.instance(force = false)
    @instance = nil if force
    @instance ||= new
  end

  def url?(url)
    url.strip =~ /^(#{UrlsParser::URL_MATCHER.source})$/ix ? true : false
  end

  def email?(email)
    email.strip =~ /^(#{UrlsParser::EMAIL_MATCHER.source})$/ix ? true : false
  end

  def domain?(domain)
    domain.strip =~ /^(#{UrlsParser::DOMAIN_MATCHER.source})$/ix ? true : false
  end

  def shortened?(url, *shortened_domains)
    domains = ["vrl.ht", "bit.ly"].concat(shortened_domains).uniq.compact.map(&:strip)
    url?(url) && (url.ensure_url_with_scheme.strip =~ /^(http(s?):\/\/(#{domains.map { |d| Regexp.quote(d) }.join("|")}))/i ? true : false)
  end

  def extract_urls(text, mode: :all, sort: nil, shortened_domains: [])
    regexp = /((^|\s+)(?<url>#{UrlsParser::URL_MATCHER.source})(#{UrlsParser::URL_SEPARATOR.source}|$))/ix
    matches = text.scan(regexp).flatten.map { |u| clean(u) }.uniq

    if mode == :shortened
      matches.select! { |u| shortened?(u, *shortened_domains) }
    elsif mode == :unshortened
      matches.reject! { |u| shortened?(u, *shortened_domains) }
    end

    matches = sort_urls(matches, sort)
    matches
  end

  def replace_urls(text, replacements: {}, mode: :all, shortened_domains: [])
    text = text.dup

    urls = extract_urls(text, mode: mode, sort: :desc, shortened_domains: shortened_domains).reduce({}) do |accu, url|
      if replacements[url]
        hash = hashify(url)
        accu["url_#{hash}"] = replacements[url].ensure_url_with_scheme
        text.gsub!(/#{Regexp.quote(url)}/, format(UrlsParser::TEMPLATE, hash))
      end

      accu
    end

    Mustache.render(text, urls: urls)
  end

  def clean(url)
    url.strip.gsub(/#{UrlsParser::URL_SEPARATOR.source}$/, "")
  end

  def hashify(url)
    Digest::MD5.hexdigest(url.strip.ensure_url_with_scheme)
  end

  private

  def sort_urls(matches, sort)
    if sort
      matches.sort! { |u1, u2| u1.length <=> u2.length }
      matches.reverse! if sort == :desc
    end

    matches
  end
end
