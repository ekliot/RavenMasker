require 'minitest/autorun'
require_relative "../raven"

class TestMasker < Minitest::Test
  def setup
    # get the script's current directory for text access
    @auth = JSON.parse( File.read( __dir__ + '/../auth.json' ) )
    @raven = Raven.new @auth

    @dummy_tag_entities = {
      :a => [ # from https://twitter.com/rayslynyrd/status/990794398148562944
        { :text => "pixel_dailies", :indices => [55, 69] },
        { :text => "pixelart", :indices => [70, 79] },
        { :text => "GiantRobot", :indices => [80, 91] },
        { :text => "ドット絵", :indices => [92, 97] }
      ],
      :b => [ # from https://twitter.com/HypnoTronic/status/988435209870823430
        {:text=>"hypnotronic", :indices=>[75, 87]},
        {:text=>"statenIsland", :indices=>[88, 101]},
        {:text=>"comics1967", :indices=>[102, 113]},
        {:text=>"warrenPub", :indices=>[114, 124]},
        {:text=>"creepy", :indices=>[125, 132]},
        {:text=>"frazetta", :indices=>[133, 142]},
        {:text=>"nealAdams", :indices=>[143, 153]},
        {:text=>"steveDitko", :indices=>[154, 165]},
        {:text=>"geneColan", :indices=>[166, 176]},
        {:text=>"reedCrandall", :indices=>[177, 190]},
        {:text=>"WallyWood", :indices=>[191, 201]},
        {:text=>"AlexToth", :indices=>[202, 211]},
        {:text=>"JohnSeverin", :indices=>[212, 224]},
        {:text=>"GrayMorrow", :indices=>[225, 236]},
        {:text=>"horrorComics", :indices=>[237, 250]}
      ]
    }

    @dummy_mention_entities = {
      a: [ # from https://twitter.com/rayslynyrd/status/990794398148562944
        { :screen_name => "Pixel_Dailies", :name => "Pixel Dailies", :id => 2586535099 }
      ]
    }

    @dummy_media_entities = {
      a: [ # from https://twitter.com/rayslynyrd/status/990794398148562944
        { :id=>990794228723732486,
          :media_url_https=>"https://pbs.twimg.com/media/DcACGgCV0AY4XDq.png",
          :type=>"photo",
          :sizes=>{ :large => { :w=>506, :h=>506, :resize=>"fit" } }
        }
      ]
    }

    @dummy_entities = {
      a: { # from https://twitter.com/rayslynyrd/status/990794398148562944
        :hashtags => @dummy_tag_entities[:a],
        :user_mentions => @dummy_mention_entities[:a],
        :media => @dummy_media_entities[:a]
      }
    }

    @dummy_tweet_users = {
      a: {
        :id => 1974602714,
        :name => "Slynyrd",
        :screen_name => "rayslynyrd",
      }
    }

    @dummy_tweets = {
      a: Twitter::Tweet.new( # from https://twitter.com/rayslynyrd/status/990794398148562944
        :id => 990794398148562944,
        :full_text => "A giant robot makes for a small village @Pixel_Dailies #pixel_dailies #pixelart #GiantRobot #ドット絵 https://t.co/V11Mvg6SjR",
        :entities => @dummy_entities[:a],
        :user => @dummy_tweet_users[:a]
      )
    }

    @example_png_url = 'https://upload.wikimedia.org/wikipedia/commons/0/06/Foo.jpg'

    # load test cases
  end

  def test_that_tweets_are_retrieved
    tweet = @raven.get_tweet @dummy_tweets[:a].id
    assert_equal @dummy_tweets[:a].attrs[:full_text], tweet.attrs[:full_text]
  end

  def test_that_tags_are_retreived
    dummy_tags = @dummy_tag_entities[:a]
    dummy_tweet = @dummy_tweets[:a]

    tags = @raven.get_tags dummy_tweet
    assert_equal dummy_tags.length, tags.length
  end

  def test_that_tags_are_converted_to_strings
    tag_strs = @raven.tags_to_strs @dummy_tweets[:a].hashtags
    dummy_tags = @dummy_tag_entities[:a].map { |t| t[:text] }
    assert_equal dummy_tags, tag_strs
  end
end

# test_tweet = r.get_tweet 986986637887463424
# test_img = test_tweet.media[0]
#
# p r.pull_img_from_url( test_img.media_url_https, 'test.png' )
