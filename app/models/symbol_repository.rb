require 'typhoeus'

class SymbolRepository < ApplicationRecord
  include SecureSerialize

  secure_serialize :settings
  before_save :generate_defaults

  def generate_defaults
    self.settings ||= {}
    self.settings['active'] = true if self.settings['active'] == nil
    self.settings['protected'] ||= false
    self.settings['name'] ||= 'Unnamed Repository'
    self.settings['n_symbols'] = PictureSymbol.where(repo_key: self.repo_key).count if self.repo_key
    self.settings['n_protected_symbols'] = self.settings['n_symbols'] if self.settings['protected']
    self.settings['n_symbols'] = 0 if self.settings['protected']
  end

  def self.retrieve_from_manifest(key, skip_update=false)
    repo_attributes, symbols = S3Bucket.retrieve_from_manifest(key)
    repo = SymbolRepository.find_or_initialize_by(:repo_key => key)
    repo.settings ||= {}
    repo.settings['active'] = true
    repo.settings['name'] = repo_attributes['name']
    repo.settings['url'] = repo_attributes['url']
    repo.settings['protected'] = repo_attributes['protected']
    repo.settings['repository_type'] = 'local'
    repo.settings['default_attribution'] = repo_attributes['default_attribution']
    repo.save
    puts "repo #{repo.id ? 'found' : 'created'} - #{symbols.length} symbols found"
    symbols.each_with_index do |symbol, idx|
      puts idx if idx % 100 == 0 && skip_update
      PictureSymbol.generate_for_repo(repo, symbol, skip_update)
    end
    repo.reload
    repo.settings['n_symbols'] = PictureSymbol.where(repo_key: repo.repo_key).count
    repo.save
    repo.settings['n_symbols']
  end

  def disable_ids(ids)
    raise "not implemented"
  #   puts "looking for #{ids.length} records"
  #   symbols = self.picture_symbols(:id => ids)
  #   puts "found #{symbols.count} records"
  #   symbols.each do |s|
  #     puts s.id
  #     s.enabled = false
  #     s.save
  #   end
  #   self.n_symbols = PictureSymbol.all(:enabled => true, :symbol_repository_id => self.id).count
  #   self.save
  # end
  end

  def missing_core_words
    lists = self.class.core_lists
    res = {}
    self.settings['defaults'] ||= {}
    lists.each do |locale, list|
      localized = self.settings['defaults'][locale] || {}
      res[locale] = []
      list.each do |word|
        res[locale] << word unless localized[word]
      end
    end
    res
  end

  def self.core_lists
    @@core_lists ||= nil
    return @@core_lists if @@core_lists
    json = JSON.parse(File.read('./lib/core_lists.json')) rescue nil
    if json
      @@core_lists = json
    end
    @@core_lists ||= []
    @@core_lists
  end

  def self.ingest(json)
    json.each do |record|
      repo = SymbolRepository.find_or_initialize_by(repo_key: record['repo_key'])
      repo.settings ||= {}
      repo.settings['name'] = record['name']
      repo.settings['active'] = !!record['active']
      repo.settings['protected'] = !!record['protected']
      repo.settings['url'] = record['url']
      repo.settings['description'] = record['description']
      repo.repo_key = record['repo_key']
      repo.settings['repository_type'] = record['repository_type']
      repo.settings['default_attribution'] = record['default_attribution']
      repo.save!
    end
  end  
  
  def self.ingest_all(url)
    res = Typhoeus.get(url)
    json = JSON.parse(res.body)
    ExternalSource.ingest(json['source'])
    # nothing worth ingesting for requests
    SymbolRepository.ingest(json['repo'])
    PictureSymbol.ingest(json['symbol'])
    {
      source: [ExternalSource.count, json['source'].length],
      repo: [SymbolRepository.count, json['repo'].length],
      symbol: [PictureSymbol.count, json['symbol'].length]
    }
  end
end
