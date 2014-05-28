#  Phusion Passenger - https://www.phusionpassenger.com/
#  Copyright (c) 2013-2014 Phusion
#
#  "Phusion Passenger" is a trademark of Hongli Lai & Ninh Bui.
#
#  See LICENSE file for license information.

PhusionPassenger.require_passenger_lib 'constants'

module PhusionPassenger

# Core of the `passenger-config` command. Dispatches a subcommand to a specific class.
module Config
	KNOWN_COMMANDS = [
		["detach-process", "DetachProcessCommand"],
		["restart-app", "RestartAppCommand"],
		["list-instances", "ListInstancesCommand"],
		["build-native-support", "BuildNativeSupportCommand"],
		["validate-install", "ValidateInstallCommand"],
		["system-metrics", "SystemMetricsCommand"],
		["about", "AboutCommand"]
	]
	
	ABOUT_OPTIONS = [
		"root",
		"includedir",
		"nginx-addon-dir",
		"nginx-libs",
		"compiled",
		"natively-packaged",
		"installed-from-release-package",
		"make-locations-ini",
		"detect-apache2",
		"ruby-command",
		"ruby-libdir",
		"rubyext-compat-id",
		"cxx-compat-id",
		"version"
	]

	def self.run!(argv)
		command_class, new_argv = lookup_command_class_by_argv(argv)
		if help_requested?(argv)
			help
		elsif help_all_requested?(argv)
			help(true)
		elsif command_class
			command = command_class.new(new_argv)
			command.run
		else
			help
			abort
		end
	end

	def self.help(all = false)
		puts "Usage: passenger-config <COMMAND> [options]"
		puts "Tool for controlling or configurating a #{PROGRAM_NAME} instance or installation."
		puts
		puts "Management commands:"
		puts "  detach-process        Detach an application process from the process pool"
		puts "  restart-app           Restart an application"
		puts
		puts "Informational commands:"
		puts "  validate-install      Validate this #{PROGRAM_NAME} installation"
		puts "  list-instances        List running #{PROGRAM_NAME} instances"
		puts "  about                 Show information about #{PROGRAM_NAME}"
		puts
		puts "Miscellaneous commands:"
		puts "  build-native-support  Ensure that the native_support library for the current"
		puts "                        Ruby interpeter is built"
		if all
			puts "  system-metrics        Display system metrics"
		end
		puts
		puts "Run 'passenger-config <COMMAND> --help' for more information about each"
		puts "command."
		if !all
			puts
			puts "There are also some advanced commands not shown in this help message. Run"
			puts "'passenger-config --help-all' to learn more about them."
		end
	end

private
	def self.help_requested?(argv)
		return argv.size == 1 && (argv[0] == "--help" || argv[0] == "-h" || argv[0] == "help")
	end

	def self.help_all_requested?(argv)
		return argv.size == 1 && (argv[0] == "--help-all" || argv[0] == "help-all")
	end

	def self.lookup_command_class_by_argv(argv)
		return nil if argv.empty?

		# Compatibility with version <= 4.0.29: try to pass all
		# --switch invocations to AboutCommand.
		if argv[0] =~ /^--/
			name = argv[0].sub(/^--/, '')
			if ABOUT_OPTIONS.include?(name)
				command_class = lookup_command_class_by_class_name("AboutCommand")
				return [command_class, argv]
			else
				return nil
			end
		end

		# Convert "passenger-config help <COMMAND>" to "passenger-config <COMMAND> --help".
		if argv.size == 2 && argv[0] == "help"
			argv = [argv[1], "--help"]
		end

		KNOWN_COMMANDS.each do |props|
			if argv[0] == props[0]
				command_class = lookup_command_class_by_class_name(props[1])
				new_argv = argv[1 .. -1]
				return [command_class, new_argv]
			end
		end

		return nil
	end

	def self.lookup_command_class_by_class_name(class_name)
		base_name = class_name.gsub(/[A-Z]/) do |match|
			"_" + match[0..0].downcase
		end
		base_name.sub!(/^_/, '')
		base_name << ".rb"
		PhusionPassenger.require_passenger_lib("config/#{base_name}")
		return PhusionPassenger::Config.const_get(class_name)
	end
end

end # module PhusionPassenger
