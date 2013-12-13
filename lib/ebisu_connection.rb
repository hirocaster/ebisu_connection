require "fresh_connection"
require "ebisu_connection/version"
require "ebisu_connection/conf_file"
require "ebisu_connection/slaves"
require "ebisu_connection/connection_manager"

FreshConnection::SlaveConnection.connection_manager = EbisuConnection::ConnectionManager
