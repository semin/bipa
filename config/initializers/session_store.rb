# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random, 
# no regular words or you'll be exposed to dictionary attacks.
ActionController::Base.session = {
  :key         => '_testrails_session',
  :secret      => '2c8a0e7837b2a72c58e7773704d5eeebddd39558428fbe132c978d6fb0e7804d10d4cee80a3ffa7c75d4f8dfbace64ec6bf2e2f30ca8a9f2c901fe26b40d5c09'
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
# ActionController::Base.session_store = :active_record_store
