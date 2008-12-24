# This is hard to test; it's nearly entirely about 3rd party integration.
#
# Mocking would test the API methods themselves, and is probably the
# best bet, but it's a great deal of work, and won't break when the
# actual API breaks.  Instead this was developed 'example first',
# basically writing code to dump my actual Google Reader data, and
# visually inspecting the result to make sure it worked.

require 'rubygems'
require 'httparty'

class GoogleReader
  include HTTParty
  base_uri 'http://www.google.com/reader'
  format :xml

  def initialize(username, password)
    auth = []
    str = HTTParty.post("https://www.google.com/accounts/ClientLogin",
                        :query =>
                        { 'accountType' => 'GOOGLE',
                          'service' => 'reader',
                          'Email' => username,
                          'Passwd' => password,
                          'source' => 'CyberFOXSoftware-ReaderInterface-1.0' })
    auth << str.split
    @cookie = auth.join('; ')
  end

  # These all follow a common pattern of state/com.google/{state}, but
  # we want more human-friendly names for the various conditions.  Since
  # exclusion is so useful, we also want to support exclusion for all of
  # the standard states.
  { :all => 'reading-list',
    :shared => 'broadcast',
    :starred => 'starred',
    :viewed => 'tracking-item-link-used',
    :followed => 'tracking-body-link-used',
  }.each do |method,madness|
    # Uses eval'ed defines here because lambda's don't allow default parameters.  :(
    eval "def #{method}(exclude=nil); state('#{madness}', exclude); end"
  end

  UNREAD='user/-/state/com.google/read'

  # In Google Reader's world, unread items are items from the reading
  # list, excluding the ones that have been read.  You could do unread items
  # from a label by passing the same string in as the exclusion.  This is made
  # easier by the UNREAD constant above.  (I.e. label('my-projects', GoogleReader.UNREAD)
  def unread
    all(UNREAD)
  end

  def label(name, exclude=nil)
    feed("label/#{name}", exclude)
  end

  def unread_count
    api('unread-count')
  end

  private
  def state(condition, exclude=nil)
    feed("state/com.google/#{condition}", exclude)
  end

  def feed(condition, exclude=nil)
    exclude = "?xt=#{exclude}" if exclude
    query("/atom/user/-/#{condition}#{exclude}")
  end

  def api(command)
    query("/api/0/#{command}")
  end

  def query(method)
    self.class.get(method, :headers => { 'Cookie' => @cookie })
  end
end

## API calls implemented
# /reader/api/0/unread-count
# /reader/atom/

## States implemented
# reading-list (in the overall list)
# read
# starred
# tracking-item-link-used (followed the main item link, or hit 'v' for 'view')
# tracking-body-link-used (followed a link in the body)

## API calls available
# /reader/api/0/preference/set
# /reader/api/0/preference/list
# /reader/api/0/search/items/ids
# /reader/api/0/stream/items/ids
# /reader/api/0/stream/details
# /reader/api/0/stream/items/contents
# /reader/api/0/stream/items/count
# /reader/api/0/preference/stream/list
# /reader/api/0/preference/stream/set
# /reader/api/0/tag/list
# /reader/api/0/edit-tag
# /reader/api/0/subscription/list
# /reader/api/0/subscription/edit
# /reader/api/0/item/delete
# /reader/api/0/item/edit
# /reader/api/0/subscription/quickadd
# /reader/api/0/mark-all-as-read
# /reader/api/0/token
# /reader/api/0/subscribed
# /reader/api/0/bundles
# /reader/api/0/recommendations
# /reader/api/0/recommended
# /reader/api/0/friend/list
# /reader/api/0/friend/edit
# /reader/api/0/unshare-all
# /reader/public/atom/
# /reader/public/javascript/
# /reader/public/javascript-sub/

## com.google states used
# kept-unread (marked unread)
# root (?)
# broadcast (shared)
# recommendations-dismissed (?)
# recommendations-subscribed (?)
# broadcast-friends (shared to contacts)
# created (?)
# self (?)
# skimmed (? read, but in 'river of news' style?)
# tracking-kept-unread (marked unread, sticks around)
# tracking-emailed (was emailed)
# blogger-following (came from the blogs you're following on blogger)
