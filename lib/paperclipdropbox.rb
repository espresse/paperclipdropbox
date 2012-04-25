module Paperclipdropbox
  require 'paperclipdropbox/railtie' if defined?(Rails)
end

module Paperclip
	module Storage
		module Dropboxstorage
    extend self
    
			def self.extended(base)
				require "dropbox_sdk"
				base.instance_eval do
					
					@dropbox_key = '8ti7qntpcysl91j'
					@dropbox_secret = 'i0tshr4cpd1pa4e'
					@dropbox_public_url = "http://dl.dropbox.com/u/"
					@options[:url] ="#{@dropbox_public_url}#{user_id}#{@options[:path]}"
					@url = @options[:url]
					@path = @options[:path]
					log("Starting up DropBox Storage")
					log(@options[:url])
				end
			end

			def exists?(style = default_style)
				log("exists?  #{style}") if respond_to?(:log)
				begin
					dropbox_client.metadata("/Public#{File.dirname(path(style))}")
					log("true") if respond_to?(:log)
					true
				rescue
					log("false") if respond_to?(:log)
					false
				end
			end

			def to_file(style=default_style)
				log("to_file  #{style}") if respond_to?(:log)
				return @queued_for_write[style] || "#{@dropbox_public_url}#{user_id}#{path(style)}"
			end

			def flush_writes #:nodoc:
				log("[paperclip] Writing files #{@queued_for_write.count}")
				@queued_for_write.each do |style, file|
					log("[paperclip] Writing files for ") if respond_to?(:log)
					#myfile = file.open
					response = dropbox_client.put_file("/Public#{File.dirname(path(style))}/#{File.basename(path(style))}", file.read)
				end
				@queued_for_write = {}
			end

			def flush_deletes #:nodoc:
				p "dfdfd"
				@queued_for_delete.each do |path|
					log("[paperclip] Deleting files for #{path}") if respond_to?(:log)
					begin
						#dropbox_session.rm("/Public/#{path}")
						dropbox_client.file_delete("/Public/#{path}")
					rescue
					end
				end
				@queued_for_delete = []
			end

			def user_id
				unless Rails.cache.exist?('DropboxClientUid')
					log("get Dropbox Session User_id")
					
					client = DropboxClient.new(dropbox_session, :dropbox)
					Rails.cache.write('DropboxClientUid', client.account_info()['uid'])
					client.account_info()['uid']
				else
					log("read Dropbox User_id") if respond_to?(:log)
					Rails.cache.read('DropboxClientUid')
				end
			end

			def dropbox_session
				unless Rails.cache.exist?('DropboxSession')
					if @dropboxsession.blank?
						log("loading session from yaml") if respond_to?(:log)
						if File.exists?("#{Rails.root}/config/dropboxsession.yml")
							@dropboxsession = DropboxSession.deserialize(File.read("#{Rails.root}/config/dropboxsession.yml"))
						end
					end
					#@dropboxsession.mode = :dropbox unless @dropboxsession.blank?
					@dropboxsession
				else
					log("reading Dropbox Session") if respond_to?(:log)
					Rails.cache.read('DropboxSession')
				end
			end

			def dropbox_client
				unless Rails.cache.exist?('DropboxClient')
					if @dropboxclient.blank?
						@dropboxclient = DropboxClient.new(dropbox_session, :dropbox)
					end
					@dropboxclient
				else
					Rails.cache.read('DropboxClient')
				end
			end
		end
	end
end
