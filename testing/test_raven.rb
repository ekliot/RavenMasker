require_relative "../raven"

# get the script's current directory for text access
@auth = JSON.parse( File.read( __dir__ + '/../auth.json' ) )

r = Raven.new @auth

test_tweet = r.get_tweet 986986637887463424
test_img = test_tweet.media[0]

p r.pull_img_from_url( test_img.media_url_https, 'test.png' )
