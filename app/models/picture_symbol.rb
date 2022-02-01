class PictureSymbol < ApplicationRecord
  include SecureSerialize

  secure_serialize :settings
  before_save :generate_defaults
  after_save :submit_to_external_index

  def generate_defaults
    self.random ||= rand(99999999)
    self.settings ||= {}
    self.settings['locales'] ||= {}
    self.settings['locales'].each do |loc, hash|
      if loc == 'en' && self.settings['name']
        hash['name'] = self.settings['name'] 
        hash.delete('name_defaulted')
      end
      if !hash['name'] || hash['name_defaulted']
        most_common = (hash['uses'] || {}).map{|str, list| list ||= []; [str, (list.is_a?(Array) ? list.length : list['count'])]}.sort_by(&:last)[-1]
        if most_common && most_common[1] > 3
          hash['name'] = most_common[0]
          hash['name_defaulted'] = true
        end
      end
    end
    self.settings['locales'].each do |loc, hash|
      (hash['uses'] || {}).each do |word, list|
        if list.is_a?(Array) && list.length > 25
          hash['uses'][word] = {'count' => list.length, 'latest' => list[-5, 5]}
        elsif list.is_a?(Hash)
          hash['uses'][word]['latest'] = (hash['uses'][word]['latest'] || [])[-5, 5]
        end
      end
    end
    self.unsafe_result = !!self.settings['unsafe_result']
    self.has_skin = !!self.settings['has_skin']
    self.generate_search_string
    self.generate_use_counts
  end

  def save_without_indexing
    @skip_indexing = true
    self.save
    @skip_indexing = false
  end

  # syms = PictureSymbol.where(repo_key: ['coughdrop','tawasol','arasaac']); syms.count
  # syms.find_in_batches(batch_size: 100) do |batch|
  #   batch.each do |sym|
  #     SymbolRepository::EXPECTED_LOCALES.each do |loc|
  #       if sym.settings['batch_translations'] && sym.settings['batch_translations'][loc]
  #         sym.settings['locales'][loc]['gtn'] = true if sym.settings['locales'][loc] && sym.settings['locales'][loc]['name']
  #       end
  #     end
  #     sym.save_without_indexing
  #   end
  #   puts "..."
  # end

  def submit_to_external_index
    return true if @skip_indexing
    locales = self.settings['locales'].keys | ['en']
    if @locales_to_index
      locales = locales & @locales_to_index
      @locales_to_index = nil
    end
    locales.uniq.each do |locale|
      if ElasticSearcher.enabled?
        if self.settings['enabled'] == false
          ElasticSearcher.remove_symbol(self, locale)
        else
          ElasticSearcher.index_symbol(self, locale)
        end
      end
    end
    true
  end

  def generate_search_string
    locales = ['en']
    self.settings['locales'] ||= {}
    locales.each do |locale|
      puts locale
      localized = self.settings['locales'][locale] || {}
      uses = []
      uses += (localized['boosts'] || {}).keys
      uses += (localized['uses'] || {}).map{|keyword, list| list ||= []; [keyword, (list.is_a?(Array) ? list.length : list['count'])] }.sort_by{|keyword, count| count }.map(&:first)
      recommendations = (localized['recommendations'] || {}).map{|keyword, list| [keyword, list.length] }.sort_by{|keyword, count| count }.map(&:first)
      name = localized['name'] || self.settings['name']
      description = localized['description'] || self.settings['description']
      localized['search_string'] = ("#{name} - #{description || ""}".downcase.sub(/^to\s/, '') + ", "  + uses.join(", ") + ", " + recommendations.join(" ")).strip
      localized['search_string'] = localized['search_string'].gsub(/[\.\(\)\/]/, '')
      self.settings['locales'][locale] = localized
    end
  end

  def generate_use_counts
    locales = ['en']
    self.settings['locales'] ||= {}
    locales.each do |locale|
      localized = self.settings['locales'][locale] || {}
      localized['use_scores'] = {}
      localized['uses'] ||= {}
      localized['boosts'] ||= {}
      localized['recommendations'] ||= {}
      (localized['uses'].keys | localized['recommendations'].keys | localized['boosts'].keys).each do |q|
        q = q.gsub(/\./, '')
        next if q.scan(/\s+/).length > 3
        uses_obj = ((localized['uses'] || {})[q] || [])
        uses = uses_obj.is_a?(Array) ? uses_obj.length : uses_obj['count']
        recommendations = ((localized['recommendations'] || {})[q] || []).length
        use_score = uses + (recommendations * 4)
        use_score = Math.log(use_score.to_f + 0.1, 4).ceil
        if localized['boosts'][q]
          use_score += localized['boosts'][q]
        end
        localized['use_scores'][q] = use_score
      end
      self.settings['locales'][locale] = localized
      self.settings['rnd'] = rand(999)
    end
  end

  def set_defaults(defaults)
    symbol = self
    repo = SymbolRepository.find_by(repo_key: self.repo_key)
    # only remember as the default for known core words,
    # otherwise just boost without marking as default
    core_lists = SymbolRepository.core_lists
    mods = {}
    if symbol && repo
      defaults.each do |locale, keyword|
        next unless keyword
        keyword = keyword.downcase
        modifier = mods[locale] || RepositoryModifier.find_for(repo, locale)
        mods[locale] = modifier
        if (core_lists[locale] || {}).include?(keyword)
          modifier.set_as_default(symbol, keyword)
        end
        symbol.boost(keyword, locale, 5, false)
      end
      symbol.save if defaults.keys.length > 0
    end
  end

  def set_as_default(keyword, locale)
    return unless keyword
    hash = {}
    hash[locale] = keyword
    set_defaults(hash)
  end

  def locale_settings
    repo = SymbolRepository.find_by(repo_key: self.repo_key)
    res = {}
    (self.settings['locales'] || {}).each do |locale, localized|
      res[locale] = {}.merge(localized.except('uses'))
      modifier = RepositoryModifier.find_for(repo, locale)
      if modifier
        res[locale]['defaults'] = modifier.settings['defaults'].select{|keyword, symbol_key| symbol_key == self.symbol_key}.map(&:first)
      end
    end
    res
  end
  
  def boost_emoji
    res = false
    if self.settings && self.settings['image_url'] && self.settings['image_url'].match(/twemoji/)
      begin
        str = self.settings['image_url'].split(/\//)[-1].split(/\./)[0]
        self.settings['emoji'] = str
        self.boost(str, 'en', nil, false)
        str = str.split(/-/).map{|s| s.hex }
        code = str.pack("U*")
        self.boost(code, 'en')
        self.b
        res = true
      rescue
      end
    end
    res
  end

  def boost(keyword, locale, factor=nil, do_save=true)
    keyword = keyword.downcase
    factor ||= 3
    symbol = self
    if symbol
      localized = symbol.settings['locales'][locale] || {}
      localized['boosts'] ||= {}
      if keyword.match(/^del:/)
        localized['boosts'].delete(keyword.sub(/^del:/, ''))
      else
        localized['boosts'][keyword] ||= 0
        localized['boosts'][keyword] += factor
      end
      symbol.settings['locales'][locale] = localized
      symbol.generate_use_counts
      symbol.save if do_save
    end
    symbol
  end

  def used_for_keyword(keyword, locale, user_id)
    keyword = keyword.downcase
    localized = self.settings['locales'][locale] || {}
    localized['uses'] ||= {}
    localized['uses'][keyword] ||= []
    if localized['uses'][keyword].is_a?(Array)
      localized['uses'][keyword] = (localized['uses'][keyword] << user_id.to_s).uniq
    elsif !(localized['uses'][keyword]['latest'] || []).include?(user_id.to_s)
      localized['uses'][keyword]['count'] += 1
      localized['uses'][keyword]['latest'] << user_id.to_s
    end
    self.settings['locales'][locale] = localized
    self.settings['rnd'] = rand(999)
    if self.updated_at < 72.hours.ago
      self.save
    else
      self.save_without_indexing
    end
  end

  def recommended_for_keyword(keyword, locale, user_id)
    keyword = keyword.downcase
    localized = self.settings['locales'][locale] || {}
    localized['recommendations'] ||= {}
    localized['recommendations'][keyword] = ((localized['recommendations'][keyword] || []) << id.to_s).uniq
    self.settings['locales'][locale] = localized
    self.settings['rnd'] = rand(999)
    self.save
  end

  def self.search(q, locale='en', safe_search=true, allow_protected=false, protected_repos=nil)
    q = q.to_s.downcase
    repo_filter = nil
    favored_repo_filter = nil
    if q.match(/repo:[\w_-]+/)
      match = q.match(/repo:([\w_-]+)/)
      repo_filter = match && match[1]
      q = q.sub(/repo:([\w_-]+)/, '')
    end
    if q.match(/favor:[\w_-]+/)
      match = q.match(/favor:([\w_-]+)/)
      favored_repo_filter = match && match[1]
      q = q.sub(/favor:([\w_-]+)/, '')
    end
    # TODO: https://gist.github.com/BrianTheCoder/217158
    if ElasticSearcher.enabled?
      res = nil
      begin
        search_opts = {
          repo_filter: repo_filter, 
          favored_repo_filter: favored_repo_filter,
          safe_search: safe_search, 
          allow_protected: allow_protected,
          protected_repos: protected_repos || []
        }
        res = ElasticSearcher.search_symbols(q, locale, search_opts)
      rescue => e
        if locale != 'en'
          res = ElasticSearcher.search_symbols(q, 'en', search_opts)
        end
      end
  
      bucket = ENV['S3_BUCKET']
      cdn = ENV['S3_CDN']
      if bucket && cdn
        res = (res || []).map do |sym|
          if sym['image_url'].match(/^https:\/\/#{bucket}\.s3\.amazonaws\.com\//) && cdn
            sym['image_url'] = sym['image_url'].sub(/^https:\/\/#{bucket}\.s3\.amazonaws\.com\//, cdn + "/")
          elsif sym['image_url'].match(/^https:\/\/s3\.amazonaws\.com\/#{bucket}\//) && cdn
            sym['image_url']= sym['image_url'].sub(/^https:\/\/s3\.amazonaws\.com\/#{bucket}\//, cdn + "/")
          end
          sym
        end
      end
    else
      raise "elastic search required"
      # results = PictureSymbol.where(:search_string.like => "%#{q.to_s}%", :enabled => true, :limit => 250, :order => random)
      # if repo_filter
      #   results = results.all(:repo_key => repo_filter)
      # end
      # results = results.select{|s| s.search_string.index(/\b#{q}\w*\b/) }
      # results = results.select{|s| s.safe_result? }
      # results = results.select{|s| allow_protected || !s.protected_symbol }
      # results = results.sort_by do |s|
      #   use_score = (s.settings['use_scores'] || {})[q] || 0
      #   [0 - use_score, (s.search_string.index(/\b#{q}\b/) ? 0 : 1), s.search_string.index(/\b#{q}\b/) || 9999, s.search_string.index(q) || 9999, s.search_string.length] 
      # end
      # results[0,50].map(&:as_json)
    end
  end

  def self.generate_for_repo(repo, data, skip_update=false, skip_indexing=false)
    repo_key = repo.repo_key
    fn = data['filename']
    symbol_key = PictureSymbol.keyify(data['name'], fn)
    symbol = PictureSymbol.find_or_initialize_by(:repo_key => repo_key, :symbol_key => symbol_key)
    locale = data['locale'] || 'en'
    already_processed = !!symbol.id
    return if already_processed && skip_update
    symbol.instance_variable_set('@skip_indexing', true)
    symbol.settings ||= {}
    symbol.settings['image_url'] = data['path'] ? "/#{data['path']}" : "/libraries/#{repo.repo_key}/#{data['filename']}"
    symbol.settings['name'] = data['name']
    symbol.settings['enabled'] = true unless data['enabled'] == false
    symbol.settings['file_extension'] = data['extension']
    symbol.settings['license'] = data['attribution']['license']
    symbol.settings['license_url'] = data['attribution']['license_url']
    symbol.settings['protected_symbol'] = true if data['protected'] || repo.settings['protected']
    symbol.settings['author'] = data['attribution']['author_name']
    symbol.settings['author_url'] = data['attribution']['author_url']
    symbol.settings['source_url'] = data['source_url']
    symbol.settings['description'] = data['description']
    symbol.settings['locales'] ||= {}
    symbol.settings['locales'][locale] ||= {}
    symbol.settings['locales'][locale]['name'] = data['name']
    symbol.settings['locales'][locale]['description'] = data['description']
    (data['locales'] || {}).each do |loc, hash|
      symbol.settings['locales'][loc] ||= {}
      if loc == locale
        symbol.settings['locales'][loc]['name'] ||= hash['name'] if hash['name']
        symbol.settings['locales'][loc]['description'] ||= hash['description'] || hash['decsription'] if (hash['description'] || hash['decsription'])
      else
        symbol.settings['locales'][loc]['name'] = hash['name'] if hash['name']
        symbol.settings['locales'][loc]['description'] = hash['description'] || hash['decsription'] if (hash['description'] || hash['decsription'])
      end
    end
    symbol.save
    if !already_processed
      defaults = {}
      (data['default_words'] || []).each do |word|
        defaults[locale] = word if word
      end
      (data['locales'] || {}).each do |loc, hash|
        (hash['default_words'] || []).each do |word|
          defaults[loc] = word if word
        end
      end
      symbol.set_defaults(defaults)
    end
    # puts symbol.obj_json.to_json
    symbol
  end

  def mark_unsafe!(unsafe=true)
    # TODO: add to UI
    self.settings['unsafe_result'] = !!unsafe
    self.save
  end

  def safe_result?
    !self.settings['unsafe_result']
  end

  def full_image_url
    return nil unless self.settings['image_url']
    url = self.settings['image_url']
    bucket = ENV['S3_BUCKET']
    cdn = ENV['S3_CDN']
    if url.match(/^\//)
      url = "https://s3.amazonaws.com/#{bucket}#{url}"
    end
    if cdn
      if url.match(/^https:\/\/#{bucket}\.s3\.amazonaws\.com\//) && cdn
        url = url.sub(/^https:\/\/#{bucket}\.s3\.amazonaws\.com\//, cdn + "/")
      elsif url.match(/^https:\/\/s3\.amazonaws\.com\/#{bucket}\//) && cdn
        url= url.sub(/^https:\/\/s3\.amazonaws\.com\/#{bucket}\//, cdn + "/")
      end
    end
    url
  end

  def obj_json(verbose=false, locale='en')
    localized = self.settings['locales'][locale] || {}
    res = {
      :id => self.id,
      :symbol_key => self.symbol_key,
      :name => localized['name'] || self.settings['name'],
      :locale => locale,
      :license => self.settings['license'],
      :license_url => self.settings['license_url'],
      :enabled => self.settings['enabled'],
      :author => self.settings['author'],
      :author_url => self.settings['author_url'],
      :source_url => self.settings['source_url'],
      :repo_key => self.repo_key,
      :hc => !!(self.settings['description'] || '').match(/\bhc\b/),
      :protected_symbol => !!self.settings['protected_symbol'],
      :extension => self.settings['file_extension'],
      :image_url => self.full_image_url,
      :search_string => localized['search_string'] || self.settings['search_string'],
      :unsafe_result => !self.safe_result?,
      :skins => !!(self.settings['has_skin'] && self.settings['has_variants']),
      :_href => "/api/v1/symbols/#{self.repo_key}/#{self.symbol_key}?id=#{self.id}",
      :details_url => "/symbols/#{self.repo_key}/#{self.symbol_key}?id=#{self.id}"
    }  
    if verbose
      res[:use_scores] = localized['use_scores'] || {}
      res[:use_scores] = res[:use_scores].slice(*res[:use_scores].keys.select{|k| k.strip.length > 0 })
    end  
    res
  end

  def self.keyify(name, filename)
    res = URI.escape(name.downcase.gsub(/[^a-z0-9]+/, '-')).sub(/^-/, '').sub(/-$/, '')
    "#{res}-#{Digest::MD5.hexdigest(filename)[0, 8]}"
  end

  def self.max_count
    @@max ||= PictureSymbol.count
  end

  def self.ingest(json)
    founds = {}
    json.each do |record|
      fn = record['image_url'].split(/\//).pop
      symbol_key = PictureSymbol.keyify(record['name'], fn)
      symbol = PictureSymbol.find_or_initialize_by(symbol_key: symbol_key, repo_key: record['repo_key'])
      if founds[symbol.id]
        puts symbol_key
        puts founds[symbol.id]
        puts JSON.pretty_generate(record)
        raise "duplicate symbol ingested!"
      end
      symbol.settings ||= {}
      symbol.settings['enabled'] = record['enabled'] == nil ? true : !!record['enabled']
      symbol.settings['protected_symbol'] = record['protected'] == nil ? true : !!record['protected']
      symbol.settings['unsafe_result'] = !!(record['settings'] && record['settings']['unsafe_result'])

      ['image_url', 'license', 'license_url', 'author', 'author_url', 'source_url', 'name', 'file_extension', 'description', 'search_string'].each do |key|
        symbol.settings[key] = record[key]
      end
      ['uses', 'boosts', 'recommendations'].each do |setting|
        symbol.settings['locales'] ||= {'en' => {}}
        if record['settings'] && record['settings'][setting]
          symbol.settings['locales']['en'][setting] = record['settings'][setting]
        end
      end
      symbol.settings = {}.merge(symbol.settings)
      symbol.save!
      founds[symbol.id] = symbol.settings['image_url']
    end    
  end
end
