require "fileutils"

class NSGrid
	def initialize(dimension)
		@dimension = dimension
		@nodes = Array.new
	end

	def createFilters(gridName, reconv = false, new = false, position = "start")
		rightNodes = Array.new
		factor = 1
		maxnode = ((@dimension*@dimension) - 1)
		
		rightNode = ((factor*@dimension) - 1)
		while (rightNode <= maxnode) do
			rightNodes.push rightNode
			factor = factor + 1;
			rightNode = ((factor*@dimension) - 1)
		end

		# Calculate the index of the node to which the nodeNew has to be added (this will be done in a later loop).
		# And at the nodeNew, add this node with the newIndex index to his filter.
		newIndex = 0
		if (new)
			nodeFilename = "#{gridName}/nodeNew.filter"
			if (position == "start")	
				newIndex = 0
				File.open(nodeFilename, 'w') do |nodeFile|
					nodeFile.puts ("node#{newIndex}")
					puts ("Index of node to which new node is added: #{newIndex}")
				end
			elsif (position == "middle")
				middle = (@dimension / 2).floor
				middle = middle + (middle * @dimension)
				newIndex = middle
				File.open(nodeFilename, 'w') do |nodeFile|
					nodeFile.puts ("node#{newIndex}")
					puts ("Index of node to which new node is added: #{newIndex}")
				end
			else
				puts "I do NOT know this position."
			end
		end
		
		for x in 0..maxnode
			nodeFilename = "#{gridName}/node#{x}.filter"
			if (reconv)
				if (x == 0)
					nodeFilename = "#{gridName}/nodeTL.filter" # Top-left node.
				elsif (x == maxnode)
					nodeFilename = "#{gridName}/nodeBR.filter" # Bottom-right node.
				end
			end
			File.open(nodeFilename, 'w') do |nodeFile|
				nodeAbove = x - @dimension
				nodeUnder = x + @dimension
				nodeLeft = x - 1
				nodeRight = x + 1
			
				# If it is a "new"-type topology, at the newIndex, add the nodeNew.
				if (new && x == newIndex)
					nodeFile.puts("nodeNew")
				end
				
				# If node x is not the first node of a row.
				if ((x % @dimension) != 0)
					if (nodeLeft >= 0)
						nodename = "node#{nodeLeft}\n"
						if (reconv)
							if (nodeLeft == 0)
								nodename = "nodeTL\n"
							elsif (nodeLeft == maxnode)
								nodename = "nodeBR\n"
							end
						end
						nodeFile.puts(nodename)
					end				
				end

				# If node x is not the last node of a row.
				if (!rightNodes.include?(x))
					nodename = "node#{nodeRight}\n"
					if (reconv)
						if (nodeRight == 0)
							nodename = "nodeTL\n"
						elsif (nodeRight == maxnode)
							nodename = "nodeBR\n"
						end
					end
					nodeFile.puts(nodename)
				end

				if (nodeAbove >= 0)
					nodename = "node#{nodeAbove}\n"
					if (reconv)
						if (nodeAbove == 0)
							nodename = "nodeTL\n"
						elsif (nodeAbove == maxnode)
							nodename = "nodeBR\n"
						end
					end
					nodeFile.puts(nodename)
				end

				if (nodeUnder <= maxnode)
					nodename = "node#{nodeUnder}\n"
					if (reconv)
						if (nodeUnder == 0)
							nodename = "nodeTL\n"
						elsif (nodeUnder == maxnode)
							nodename = "nodeBR\n"
						end
					end
					nodeFile.puts(nodename)
				end
			end
		end
	end

	def createGridOLSRd
		puts "Normal OLSR topology."
		# Create a new file and write to it
		t = Time.now
		gridName = t.strftime("GRID-OLSRd-DEFAULT-#{(@dimension*@dimension)}-%Y-%m-%d-%H-%M-%S")
		FileUtils.mkdir gridName
		filename = "#{gridName}/#{gridName}.ns"
		createFilters(gridName)
		File.open(filename, 'w') do |file|  
  			# use "\n" for two lines of text  
  			file.puts "set ns [new Simulator]\n"			
        		file.puts "source tb_compat.tcl\n\n"
			
			#file.puts "set nodeGroup [$ns event-group]\n"
			#file.puts "set nodeGroupFilter [$ns event-group]\n"
			#file.puts "set nodeGroupOLSRd [$ns event-group]\n\n"

			file.puts "set nodeGroupInstall [$ns event-group]\n"
			file.puts "set nodeGroupSetIPv6 [$ns event-group]\n"
			file.puts "set nodeGroupWriteIPv6 [$ns event-group]\n"
			file.puts "set nodeGroupFilter [$ns event-group]\n"
			file.puts "set nodeGroupRouteCheck [$ns event-group]\n"
			file.puts "set nodeGroupInstallOLSRd [$ns event-group]\n"
			file.puts "set nodeGroupOLSRd [$ns event-group]\n"

			file.puts "set monitorSetupEnv [$ns event-group]\n"
			file.puts "set monitorSetRouter [$ns event-group]\n"
			file.puts "set monitorFailPass [$ns event-group]\n"
			file.puts "set monitorStartTcpdump [$ns event-group]\n"
			file.puts "set monitorStopTcpdump [$ns event-group]\n"
			file.puts "set monitorIntervalLog [$ns event-group]\n"

			maxnode = ((@dimension*@dimension) - 1)
			for i in 0..maxnode
				#node = "node#{i}"
				#@nodes.push node
				#file.puts "set #{node} [$ns node]\n"
				#file.puts "append lanstr \"$#{node} \"\n"
				#file.puts "set progStartFilter_#{node} [$#{node} program-agent -command \"/proj/CONFINE/runme/runme.nodeStartFilter\"]\n"
				#file.puts "set progStartOLSRd_#{node} [$#{node} program-agent -command \"/proj/CONFINE/runme/runme.nodeStartOLSRd\"]\n"
				#file.puts "$nodeGroupFilter add $progStartFilter_#{node}\n"
				#file.puts "$nodeGroupOLSRd add $progStartOLSRd_#{node}\n\n"

				node = "#{i}"
				@nodes.push node
				file.puts "set node#{node} [$ns node]\n"
				# Automatically place BMX6 on the node (in dir /usr/local/src).
				file.puts "tb-set-node-tarfiles $node#{node} /usr/local/src/ /proj/CONFINE/tarfiles/olsrd-0.6.5.2.tar.gz"
				file.puts "append lanstr \"$node#{node} \"\n"

				file.puts "set progInstall#{node} [$node#{node} program-agent -command \"sudo /proj/CONFINE/runme-OLSR/virtual/install_ip6tables.sh\"]\n"
				file.puts "set progInstallOLSRd#{node} [$node#{node} program-agent -command \"/proj/CONFINE/runme-OLSR/virtual/install_OLSR.sh\"]\n"
				file.puts "set progSetIPv6#{node} [$node#{node} program-agent -command \"/proj/CONFINE/runme-OLSR/virtual/setIPv6.sh\"]\n"
				file.puts "set progWriteIPv6#{node} [$node#{node} program-agent -command \"/proj/CONFINE/runme-OLSR/virtual/ipv6tofile.sh\"]\n"
				file.puts "set progFilter#{node} [$node#{node} program-agent -command \"/proj/CONFINE/runme-OLSR/virtual/filter_ip6tables.sh\"]\n"
				file.puts "set progRouteCheck#{node} [$node#{node} program-agent -command \"/proj/CONFINE/runme-OLSR/virtual/routeCheck.sh\"]\n"
				file.puts "set progOLSRd#{node} [$node#{node} program-agent -command \"/proj/CONFINE/runme-OLSR/virtual/start_OLSR.sh\"]\n"

				file.puts "$nodeGroupInstall add $progInstall#{node}\n"
				file.puts "$nodeGroupInstallOLSRd add $progInstallOLSRd#{node}\n"
				file.puts "$nodeGroupSetIPv6 add $progSetIPv6#{node}\n"
    				file.puts "$nodeGroupWriteIPv6 add $progWriteIPv6#{node}\n"
				file.puts "$nodeGroupFilter add $progFilter#{node}\n"
				file.puts "$nodeGroupRouteCheck add $progRouteCheck#{node}\n"
    				file.puts "$nodeGroupOLSRd add $progOLSRd#{node}\n"
				file.puts "\n"
			end

			for i in 0..maxnode
				node = "node#{i}"
				file.puts "tb-set-hardware $#{node} pcvm\n"
				file.puts "tb-set-node-os $#{node} OPENVZ-STD\n"
			end
			file.puts "\n"

			#file.puts "set nodeMonitor [$ns node]\n"
			#file.puts "tb-set-node-os $nodeMonitor UBUNTU12-64-STD\n"
			#file.puts "append lanstr \"$nodeMonitor \"\n"
			#file.puts "\n"

			#file.puts "set lan0 [$ns make-lan \"$lanstr\" 1000Mb 0ms]\n"
			#file.puts "\n"
			
			#file.puts "$ns at 60 \"$nodeGroupFilter start\"\n"
			#file.puts "$ns at 120 \"$nodeGroupOLSRd start\"\n"
			#file.puts "$ns at 600 \"$nodeGroup start\"\n"

			file.puts "set nodeMonitor [$ns node]\n"
			file.puts "tb-set-hardware $nodeMonitor pcvm\n"
			file.puts "tb-set-node-os $nodeMonitor OPENVZ-STD\n"

			file.puts "set progSetupEnv [$nodeMonitor program-agent -command \"/proj/CONFINE/runme-OLSR/virtual/setup_exp_env.sh\"]\n"
			file.puts "set progSetRouter [$nodeMonitor program-agent -command \"sudo /proj/CONFINE/runme-OLSR/virtual/setRouter.sh\"]\n"			
			file.puts "set progFailPass [$nodeMonitor program-agent -command \"sudo /proj/CONFINE/runme-OLSR/virtual/failpass.sh #{@nodes.length}\"]\n"
			file.puts "set progStartTcpdump [$nodeMonitor program-agent -command \"/proj/CONFINE/runme-OLSR/virtual/start_tcpdump.sh\"]\n"
			file.puts "set progIntervalLog [$nodeMonitor program-agent -command \"/proj/CONFINE/runme-OLSR/virtual/start_interval_logging_special.sh\"]\n"
			file.puts "set progStopTcpdump [$nodeMonitor program-agent -command \"/proj/CONFINE/runme-OLSR/virtual/stop_tcpdump.sh\"]\n"
			file.puts "$monitorSetupEnv add $progSetupEnv\n"
			file.puts "$monitorSetRouter add $progSetRouter\n"
			file.puts "$monitorFailPass add $progFailPass\n"
			file.puts "$monitorStartTcpdump add $progStartTcpdump\n"
			file.puts "$monitorIntervalLog add $progIntervalLog\n"
    			file.puts "$monitorStopTcpdump add $progStopTcpdump\n"
			file.puts "append lanstr \"$nodeMonitor \"\n"
			file.puts "\n"

			file.puts "set nodePhysical [$ns node]\n"
			file.puts "tb-set-node-os $nodePhysical UBUNTU12-64-STD\n"
			file.puts "append lanstr \"$nodePhysical \"\n"
			file.puts "\n"

			file.puts "set big-lan [$ns make-lan \"$lanstr\" 100Mb 20ms]\n"
			file.puts "\n"

			file.puts "$ns at 30 \"$monitorSetupEnv start\"\n"
			file.puts "$ns at 40 \"$monitorSetRouter start\"\n"
			file.puts "$ns at 50 \"$nodeGroupInstall start\"\n"
			file.puts "$ns at 55 \"$nodeGroupInstallOLSRd start\"\n"
			file.puts "$ns at 180 \"$nodeGroupSetIPv6 start\"\n"
			file.puts "$ns at 220 \"$nodeGroupWriteIPv6 start\"\n"
			file.puts "$ns at 260 \"$monitorFailPass start\"\n"
			file.puts "$ns at 280 \"$nodeGroupFilter start\"\n"
			file.puts "$ns at 310 \"$nodeGroupRouteCheck start\"\n"
			file.puts "$ns at 320 \"$monitorStartTcpdump start\"\n"
			file.puts "$ns at 338 \"$monitorIntervalLog start\"\n"
			file.puts "$ns at 340 \"$nodeGroupOLSRd start\"\n"
			
			file.puts "# $ns at 540.0 \"$ns swapout\"\n"

			file.puts "\n"
			file.puts "$ns run"
		end	
	end

	def createGridOLSRdNewNode(position)
		puts "New node OLSR topology."
		# Create a new file and write to it
		t = Time.now
		gridName = t.strftime("GRID-OLSRd-NEWNODE-#{(@dimension*@dimension)}-#{position}-%Y-%m-%d-%H-%M-%S")
		FileUtils.mkdir gridName
		filename = "#{gridName}/#{gridName}.ns"
		createFilters(gridName, false, true, position)
		File.open(filename, 'w') do |file|  
  			# use "\n" for two lines of text  
  			file.puts "set ns [new Simulator]\n"			
        		file.puts "source tb_compat.tcl\n\n"
			
			#file.puts "set nodeGroup [$ns event-group]\n"
			#file.puts "set nodeGroupFilter [$ns event-group]\n"
			#file.puts "set nodeGroupOLSRd [$ns event-group]\n\n"

			file.puts "set nodeGroupInstall [$ns event-group]\n"
			file.puts "set nodeGroupSetIPv6 [$ns event-group]\n"
			file.puts "set nodeGroupWriteIPv6 [$ns event-group]\n"
			file.puts "set nodeGroupFilter [$ns event-group]\n"
			file.puts "set nodeGroupRouteCheck [$ns event-group]\n"
			file.puts "set nodeGroupInstallOLSRd [$ns event-group]\n"
			file.puts "set nodeGroupOLSRd [$ns event-group]\n"
			file.puts "set nodeGroupStartAndRC [$ns event-group]\n"

			file.puts "set monitorSetupEnv [$ns event-group]\n"
			file.puts "set monitorSetRouter [$ns event-group]\n"
			file.puts "set monitorFailPass [$ns event-group]\n"
			file.puts "set monitorStartTcpdump [$ns event-group]\n"
			file.puts "set monitorStopTcpdump [$ns event-group]\n"
			file.puts "set monitorIntervalLog [$ns event-group]\n\n"

			maxnode = ((@dimension*@dimension) - 1)
			for i in 0..maxnode
				#node = "node#{i}"
				#@nodes.push node
				#file.puts "set #{node} [$ns node]\n"
				#file.puts "append lanstr \"$#{node} \"\n"
				#file.puts "set progStartFilter_#{node} [$#{node} program-agent -command \"/proj/CONFINE/runme/runme.nodeStartFilter\"]\n"
				#file.puts "set progStartOLSRd_#{node} [$#{node} program-agent -command \"/proj/CONFINE/runme/runme.nodeStartOLSRd\"]\n"
				#file.puts "$nodeGroupFilter add $progStartFilter_#{node}\n"
				#file.puts "$nodeGroupOLSRd add $progStartOLSRd_#{node}\n\n"

				node = "#{i}"
				@nodes.push node
				file.puts "set node#{node} [$ns node]\n"
				# Automatically place BMX6 on the node (in dir /usr/local/src).
				file.puts "tb-set-node-tarfiles $node#{node} /usr/local/src/ /proj/CONFINE/tarfiles/olsrd-0.6.5.2.tar.gz"
				file.puts "append lanstr \"$node#{node} \"\n"

				file.puts "set progInstall#{node} [$node#{node} program-agent -command \"sudo /proj/CONFINE/runme-OLSR/virtual/install_ip6tables.sh\"]\n"
				file.puts "set progInstallOLSRd#{node} [$node#{node} program-agent -command \"/proj/CONFINE/runme-OLSR/virtual/install_OLSR.sh\"]\n"
				file.puts "set progSetIPv6#{node} [$node#{node} program-agent -command \"/proj/CONFINE/runme-OLSR/virtual/setIPv6.sh\"]\n"
				file.puts "set progWriteIPv6#{node} [$node#{node} program-agent -command \"/proj/CONFINE/runme-OLSR/virtual/ipv6tofile.sh\"]\n"
				file.puts "set progFilter#{node} [$node#{node} program-agent -command \"/proj/CONFINE/runme-OLSR/virtual/filter_ip6tables.sh\"]\n"
				file.puts "set progRouteCheck#{node} [$node#{node} program-agent -command \"/proj/CONFINE/runme-OLSR/virtual/routeCheck.sh\"]\n"
				file.puts "set progOLSRd#{node} [$node#{node} program-agent -command \"/proj/CONFINE/runme-OLSR/virtual/start_OLSR.sh\"]\n"
				file.puts "set progStartRCAddNode#{node} [$node#{node} program-agent -command \"/proj/CONFINE/runme-OLSR/virtual/start_rc_addnode.sh\"]\n"

				file.puts "$nodeGroupInstall add $progInstall#{node}\n"
				file.puts "$nodeGroupInstallOLSRd add $progInstallOLSRd#{node}\n"
				file.puts "$nodeGroupSetIPv6 add $progSetIPv6#{node}\n"
    				file.puts "$nodeGroupWriteIPv6 add $progWriteIPv6#{node}\n"
				file.puts "$nodeGroupFilter add $progFilter#{node}\n"
				file.puts "$nodeGroupRouteCheck add $progRouteCheck#{node}\n"
    				file.puts "$nodeGroupOLSRd add $progOLSRd#{node}\n"
				file.puts "$nodeGroupStartAndRC add $progStartRCAddNode#{node}\n"
				file.puts "\n"
			end

			for i in 0..maxnode
				node = "node#{i}"
				file.puts "tb-set-hardware $#{node} pcvm\n"
				file.puts "tb-set-node-os $#{node} OPENVZ-STD\n"
			end
			file.puts "\n"

			node = "New"
			file.puts "set node#{node} [$ns node]\n"
			# Automatically place BMX6 on the node (in dir /usr/local/src).
			file.puts "tb-set-node-tarfiles $node#{node} /usr/local/src/ /proj/CONFINE/tarfiles/olsrd-0.6.5.2.tar.gz"
			file.puts "append lanstr \"$node#{node} \"\n"

			file.puts "set progInstall#{node} [$node#{node} program-agent -command \"sudo /proj/CONFINE/runme-OLSR/virtual/install_ip6tables.sh\"]\n"
			file.puts "set progInstallOLSRd#{node} [$node#{node} program-agent -command \"/proj/CONFINE/runme-OLSR/virtual/install_OLSR.sh\"]\n"
			file.puts "set progSetIPv6#{node} [$node#{node} program-agent -command \"/proj/CONFINE/runme-OLSR/virtual/setIPv6.sh\"]\n"
			file.puts "set progWriteIPv6#{node} [$node#{node} program-agent -command \"/proj/CONFINE/runme-OLSR/virtual/ipv6tofile.sh\"]\n"
			file.puts "set progFilter#{node} [$node#{node} program-agent -command \"/proj/CONFINE/runme-OLSR/virtual/filter_ip6tables.sh\"]\n"
			file.puts "set progStartAndRC#{node} [$node#{node} program-agent -command \"/proj/CONFINE/runme-OLSR/virtual/start_and_rc_addnode.sh\"]\n"
			
			file.puts "$nodeGroupInstall add $progInstall#{node}\n"
			file.puts "$nodeGroupInstallOLSRd add $progInstallOLSRd#{node}\n"
			file.puts "$nodeGroupSetIPv6 add $progSetIPv6#{node}\n"
    			file.puts "$nodeGroupWriteIPv6 add $progWriteIPv6#{node}\n"
			file.puts "$nodeGroupFilter add $progFilter#{node}\n"
			file.puts "$nodeGroupStartAndRC add $progStartAndRC#{node}\n"

			file.puts "\n"

			node = "nodeNew"
			file.puts "tb-set-hardware $#{node} pcvm\n"
			file.puts "tb-set-node-os $#{node} OPENVZ-STD\n"
			file.puts "\n"

			file.puts "set nodeMonitor [$ns node]\n"
			file.puts "tb-set-hardware $nodeMonitor pcvm\n"
			file.puts "tb-set-node-os $nodeMonitor OPENVZ-STD\n"

			file.puts "set progSetupEnv [$nodeMonitor program-agent -command \"/proj/CONFINE/runme-OLSR/virtual/setup_exp_env.sh\"]\n"
			file.puts "set progSetRouter [$nodeMonitor program-agent -command \"sudo /proj/CONFINE/runme-OLSR/virtual/setRouter.sh\"]\n"			
			file.puts "set progFailPass [$nodeMonitor program-agent -command \"sudo /proj/CONFINE/runme-OLSR/virtual/failpass.sh #{@nodes.length}\"]\n"
			#file.puts "set progStartTcpdump [$nodeMonitor program-agent -command \"/proj/CONFINE/runme-OLSR/virtual/start_tcpdump.sh\"]\n"
			file.puts "set progIntervalLog [$nodeMonitor program-agent -command \"/proj/CONFINE/runme-OLSR/virtual/start_interval_logging_special.sh\"]\n"
			#file.puts "set progStopTcpdump [$nodeMonitor program-agent -command \"/proj/CONFINE/runme-OLSR/virtual/stop_tcpdump.sh\"]\n"
			file.puts "$monitorSetupEnv add $progSetupEnv\n"
			file.puts "$monitorSetRouter add $progSetRouter\n"
			file.puts "$monitorFailPass add $progFailPass\n"
			#file.puts "$monitorStartTcpdump add $progStartTcpdump\n"
			file.puts "$monitorIntervalLog add $progIntervalLog\n"
    			#file.puts "$monitorStopTcpdump add $progStopTcpdump\n"
			file.puts "append lanstr \"$nodeMonitor \"\n"
			file.puts "\n"

			file.puts "set nodePhysical [$ns node]\n"
			file.puts "tb-set-node-os $nodePhysical UBUNTU12-64-STD\n"
			file.puts "append lanstr \"$nodePhysical \"\n"
			file.puts "\n"

			file.puts "set big-lan [$ns make-lan \"$lanstr\" 100Mb 20ms]\n"
			file.puts "\n"

			file.puts "$ns at 30 \"$monitorSetupEnv start\"\n"
			file.puts "$ns at 40 \"$monitorSetRouter start\"\n"
			file.puts "$ns at 50 \"$nodeGroupInstall start\"\n"
			file.puts "$ns at 55 \"$nodeGroupInstallOLSRd start\"\n"
			file.puts "$ns at 180 \"$nodeGroupSetIPv6 start\"\n"
			file.puts "$ns at 220 \"$nodeGroupWriteIPv6 start\"\n"
			file.puts "$ns at 260 \"$monitorFailPass start\"\n"
			file.puts "$ns at 280 \"$nodeGroupFilter start\"\n"
			file.puts "$ns at 310 \"$nodeGroupRouteCheck start\"\n"
			#file.puts "$ns at 320 \"$monitorStartTcpdump start\"\n"
			file.puts "$ns at 338 \"$monitorIntervalLog start\"\n"
			file.puts "$ns at 340 \"$nodeGroupOLSRd start\"\n"
			#file.puts "$ns at 540 \"$monitorStopTcpdump start\"\n"
			file.puts "$ns at 600 \"$nodeGroupStartAndRC start\"\n"
			
			file.puts "# $ns at 540.0 \"$ns swapout\"\n"

			file.puts "\n"
			file.puts "$ns run"
		end	
	end

	def createGridOLSRdReconvergence
		puts "Reconvergence OLSR topology."
		# Create a new file and write to it
		t = Time.now
		gridName = t.strftime("GRID-OLSRd-RECONVERGENCE-#{(@dimension*@dimension)}-%Y-%m-%d-%H-%M-%S")
		FileUtils.mkdir gridName
		filename = "#{gridName}/#{gridName}.ns"
		createFilters(gridName, true)
		File.open(filename, 'w') do |file|  
  			# use "\n" for two lines of text  
  			file.puts "set ns [new Simulator]\n"			
        		file.puts "source tb_compat.tcl\n\n"
			
			#file.puts "set nodeGroup [$ns event-group]\n"
			#file.puts "set nodeGroupFilter [$ns event-group]\n"
			#file.puts "set nodeGroupOLSRd [$ns event-group]\n\n"

			file.puts "set nodeGroupInstall [$ns event-group]\n"
			file.puts "set nodeGroupSetIPv6 [$ns event-group]\n"
			file.puts "set nodeGroupWriteIPv6 [$ns event-group]\n"
			file.puts "set nodeGroupFilter [$ns event-group]\n"
			file.puts "set nodeGroupRouteCheck [$ns event-group]\n"
			file.puts "set nodeGroupInstallOLSRd [$ns event-group]\n"
			file.puts "set nodeGroupOLSRd [$ns event-group]\n"
			file.puts "set nodeGroupStartReconv [$ns event-group]\n"

			file.puts "set monitorSetupEnv [$ns event-group]\n"
			file.puts "set monitorSetRouter [$ns event-group]\n"
			file.puts "set monitorFailPass [$ns event-group]\n"
			file.puts "set monitorStartTcpdump [$ns event-group]\n"
			file.puts "set monitorStopTcpdump [$ns event-group]\n"
			file.puts "set monitorIntervalLog [$ns event-group]\n"
			file.puts "\n"

			maxnode = ((@dimension*@dimension) - 1)
			for i in 0..maxnode
				#node = "node#{i}"
				#@nodes.push node
				#file.puts "set #{node} [$ns node]\n"
				#file.puts "append lanstr \"$#{node} \"\n"
				#file.puts "set progStartFilter_#{node} [$#{node} program-agent -command \"/proj/CONFINE/runme/runme.nodeStartFilter\"]\n"
				#file.puts "set progStartOLSRd_#{node} [$#{node} program-agent -command \"/proj/CONFINE/runme/runme.nodeStartOLSRd\"]\n"
				#file.puts "$nodeGroupFilter add $progStartFilter_#{node}\n"
				#file.puts "$nodeGroupOLSRd add $progStartOLSRd_#{node}\n\n"

				node = "#{i}"
				if (i == 0)
					node = "TL" # Top-left node.
				elsif (i == maxnode)
					node = "BR" # Bottom-right node.
				end
				@nodes.push node
				file.puts "set node#{node} [$ns node]\n"
				# Automatically place BMX6 on the node (in dir /usr/local/src).
				file.puts "tb-set-node-tarfiles $node#{node} /usr/local/src/ /proj/CONFINE/tarfiles/olsrd-0.6.5.2.tar.gz"
				file.puts "append lanstr \"$node#{node} \"\n"

				file.puts "set progInstall#{node} [$node#{node} program-agent -command \"sudo /proj/CONFINE/runme-OLSR/virtual/install_ip6tables.sh\"]\n"
				file.puts "set progInstallOLSRd#{node} [$node#{node} program-agent -command \"/proj/CONFINE/runme-OLSR/virtual/install_OLSR.sh\"]\n"
				file.puts "set progSetIPv6#{node} [$node#{node} program-agent -command \"/proj/CONFINE/runme-OLSR/virtual/setIPv6.sh\"]\n"
				file.puts "set progWriteIPv6#{node} [$node#{node} program-agent -command \"/proj/CONFINE/runme-OLSR/virtual/ipv6tofile.sh\"]\n"
				file.puts "set progFilter#{node} [$node#{node} program-agent -command \"/proj/CONFINE/runme-OLSR/virtual/filter_ip6tables.sh\"]\n"
				file.puts "set progRouteCheck#{node} [$node#{node} program-agent -command \"/proj/CONFINE/runme-OLSR/virtual/routeCheck.sh\"]\n"
				file.puts "set progOLSRd#{node} [$node#{node} program-agent -command \"/proj/CONFINE/runme-OLSR/virtual/start_OLSR.sh\"]\n"

				if (node == "TL")
					file.puts "set progStartReconv#{node} [$node#{node} program-agent -command \"/proj/CONFINE/runme-OLSR/virtual/start_reconv.sh nodeBR\"]\n"
					file.puts "$nodeGroupStartReconv add $progStartReconv#{node}\n"
				elsif (node == "BR")
					file.puts "set progStartReconv#{node} [$node#{node} program-agent -command \"/proj/CONFINE/runme-OLSR/virtual/start_reconv.sh nodeTL\"]\n"
					file.puts "$nodeGroupStartReconv add $progStartReconv#{node}\n"
				end

				file.puts "$nodeGroupInstall add $progInstall#{node}\n"
				file.puts "$nodeGroupInstallOLSRd add $progInstallOLSRd#{node}\n"
				file.puts "$nodeGroupSetIPv6 add $progSetIPv6#{node}\n"
    				file.puts "$nodeGroupWriteIPv6 add $progWriteIPv6#{node}\n"
				file.puts "$nodeGroupFilter add $progFilter#{node}\n"
				file.puts "$nodeGroupRouteCheck add $progRouteCheck#{node}\n"
    				file.puts "$nodeGroupOLSRd add $progOLSRd#{node}\n"
				file.puts "\n"
			end

			for i in 0..maxnode
				node = "node#{i}"
				if (i == 0)
					node = "nodeTL" # Top-left node.
				elsif (i == maxnode)
					node = "nodeBR" # Bottom-right node.
				end
				file.puts "tb-set-hardware $#{node} pcvm\n"
				file.puts "tb-set-node-os $#{node} OPENVZ-STD\n"
			end
			file.puts "\n"

			#file.puts "set nodeMonitor [$ns node]\n"
			#file.puts "tb-set-node-os $nodeMonitor UBUNTU12-64-STD\n"
			#file.puts "append lanstr \"$nodeMonitor \"\n"
			#file.puts "\n"

			#file.puts "set lan0 [$ns make-lan \"$lanstr\" 1000Mb 0ms]\n"
			#file.puts "\n"
			
			#file.puts "$ns at 60 \"$nodeGroupFilter start\"\n"
			#file.puts "$ns at 120 \"$nodeGroupOLSRd start\"\n"
			#file.puts "$ns at 600 \"$nodeGroup start\"\n"

			file.puts "set nodeMonitor [$ns node]\n"
			file.puts "tb-set-hardware $nodeMonitor pcvm\n"
			file.puts "tb-set-node-os $nodeMonitor OPENVZ-STD\n"

			file.puts "set progSetupEnv [$nodeMonitor program-agent -command \"/proj/CONFINE/runme-OLSR/virtual/setup_exp_env.sh\"]\n"
			file.puts "set progSetRouter [$nodeMonitor program-agent -command \"sudo /proj/CONFINE/runme-OLSR/virtual/setRouter.sh\"]\n"			
			file.puts "set progFailPass [$nodeMonitor program-agent -command \"sudo /proj/CONFINE/runme-OLSR/virtual/failpass.sh #{@nodes.length}\"]\n"
			#file.puts "set progStartTcpdump [$nodeMonitor program-agent -command \"/proj/CONFINE/runme-OLSR/virtual/start_tcpdump.sh\"]\n"
			file.puts "set progIntervalLog [$nodeMonitor program-agent -command \"/proj/CONFINE/runme-OLSR/virtual/start_interval_logging_special.sh\"]\n"
			#file.puts "set progStopTcpdump [$nodeMonitor program-agent -command \"/proj/CONFINE/runme-OLSR/virtual/stop_tcpdump.sh\"]\n"
			file.puts "$monitorSetupEnv add $progSetupEnv\n"
			file.puts "$monitorSetRouter add $progSetRouter\n"
			file.puts "$monitorFailPass add $progFailPass\n"
			#file.puts "$monitorStartTcpdump add $progStartTcpdump\n"
			file.puts "$monitorIntervalLog add $progIntervalLog\n"
    			#file.puts "$monitorStopTcpdump add $progStopTcpdump\n"
			file.puts "append lanstr \"$nodeMonitor \"\n"
			file.puts "\n"

			file.puts "set nodePhysical [$ns node]\n"
			file.puts "tb-set-node-os $nodePhysical UBUNTU12-64-STD\n"
			file.puts "append lanstr \"$nodePhysical \"\n"
			file.puts "\n"

			file.puts "set big-lan [$ns make-lan \"$lanstr\" 100Mb 20ms]\n"
			file.puts "\n"

			file.puts "$ns at 30 \"$monitorSetupEnv start\"\n"
			file.puts "$ns at 40 \"$monitorSetRouter start\"\n"
			file.puts "$ns at 50 \"$nodeGroupInstall start\"\n"
			file.puts "$ns at 55 \"$nodeGroupInstallOLSRd start\"\n"
			file.puts "$ns at 180 \"$nodeGroupSetIPv6 start\"\n"
			file.puts "$ns at 220 \"$nodeGroupWriteIPv6 start\"\n"
			file.puts "$ns at 260 \"$monitorFailPass start\"\n"
			file.puts "$ns at 280 \"$nodeGroupFilter start\"\n"
			file.puts "$ns at 310 \"$nodeGroupRouteCheck start\"\n"
			#file.puts "$ns at 320 \"$monitorStartTcpdump start\"\n"
			file.puts "$ns at 338 \"$monitorIntervalLog start\"\n"
			file.puts "$ns at 340 \"$nodeGroupOLSRd start\"\n"
			#file.puts "$ns at 540 \"$monitorStopTcpdump start\"\n"
			file.puts "$ns at 580 \"$nodeGroupStartReconv start\"\n"
			
			file.puts "# $ns at 540.0 \"$ns swapout\"\n"

			file.puts "\n"
			file.puts "$ns run"
		end	
	end

	def createGridBMX6
		puts "Normal BMX6 topology."
		# Create a new file and write to it
		t = Time.now
		gridName = t.strftime("GRID-BMX6-DEFAULT-#{(@dimension*@dimension)}-%Y-%m-%d-%H-%M-%S")
		FileUtils.mkdir gridName
		filename = "#{gridName}/#{gridName}.ns"
		createFilters(gridName)
		File.open(filename, 'w') do |file|  
  			# use "\n" for two lines of text  
  			file.puts "set ns [new Simulator]\n"			
        		file.puts "source tb_compat.tcl\n\n"
			
			#file.puts "set nodeGroupFilter [$ns event-group]\n"
			#file.puts "set nodeGroupBMX6 [$ns event-group]\n"
			#file.puts "set monitorStartTcpdump [$ns event-group]\n"
			#file.puts "set monitorStopTcpdump [$ns event-group]\n\n"

			file.puts "set nodeGroupInstall [$ns event-group]\n"
			file.puts "set nodeGroupWriteIPv6 [$ns event-group]\n"
			file.puts "set nodeGroupFilter [$ns event-group]\n"
			file.puts "set nodeGroupRouteCheck [$ns event-group]\n"
			file.puts "set nodeGroupInstallBMX6 [$ns event-group]\n"
			file.puts "set nodeGroupBMX6 [$ns event-group]\n"

			file.puts "set monitorSetupEnv [$ns event-group]\n"
			file.puts "set monitorSetRouter [$ns event-group]\n"
			file.puts "set monitorFailPass [$ns event-group]\n"
			file.puts "set monitorStartTcpdump [$ns event-group]\n"
			file.puts "set monitorStopTcpdump [$ns event-group]\n"
			file.puts "set monitorIntervalLog [$ns event-group]\n"

			maxnode = ((@dimension*@dimension) - 1)
			for i in 0..maxnode
				#node = "node#{i}"
				#@nodes.push node
				#file.puts "set #{node} [$ns node]\n"
				#file.puts "append lanstr \"$#{node} \"\n"
				#file.puts "set progStartFilter#{node} [$#{node} program-agent -command \"/proj/CONFINE/runme/virt/runme.vnodeStartFilter\"]\n"
				#file.puts "set progStartBMX6#{node} [$#{node} program-agent -command \"/proj/CONFINE/runme/virt/runme.vnodeStartBMX6\"]\n"
				#file.puts "$nodeGroupFilter add $progStartFilter#{node}\n"
				#file.puts "$nodeGroupBMX6 add $progStartBMX6#{node}\n\n"

				node = "#{i}"
				@nodes.push node
				file.puts "set node#{node} [$ns node]\n"
				# Automatically place BMX6 on the node (in dir /usr/local/src).
				file.puts "tb-set-node-tarfiles $node#{node} /usr/local/src/ /proj/CONFINE/tarfiles/bmx6.tar.gz"
				file.puts "append lanstr \"$node#{node} \"\n"

				file.puts "set progInstall#{node} [$node#{node} program-agent -command \"sudo /proj/CONFINE/runme-BMX6/virtual/install_ip6tables.sh\"]\n"
				file.puts "set progInstallBMX6#{node} [$node#{node} program-agent -command \"/proj/CONFINE/runme-BMX6/virtual/install_BMX6.sh\"]\n"
				file.puts "set progWriteIPv6#{node} [$node#{node} program-agent -command \"/proj/CONFINE/runme-BMX6/virtual/ipv6tofile.sh\"]\n"
				file.puts "set progFilter#{node} [$node#{node} program-agent -command \"/proj/CONFINE/runme-BMX6/virtual/filter_ip6tables.sh\"]\n"
				file.puts "set progRouteCheck#{node} [$node#{node} program-agent -command \"/proj/CONFINE/runme-BMX6/virtual/routeCheck.sh\"]\n"
				file.puts "set progBMX6#{node} [$node#{node} program-agent -command \"/proj/CONFINE/runme-BMX6/virtual/start_BMX6.sh\"]\n"

				file.puts "$nodeGroupInstall add $progInstall#{node}\n"
				file.puts "$nodeGroupInstallBMX6 add $progInstallBMX6#{node}\n"
    				file.puts "$nodeGroupWriteIPv6 add $progWriteIPv6#{node}\n"
				file.puts "$nodeGroupFilter add $progFilter#{node}\n"
				file.puts "$nodeGroupRouteCheck add $progRouteCheck#{node}\n"
    				file.puts "$nodeGroupBMX6 add $progBMX6#{node}\n"
				file.puts "\n"
			end

			for i in 0..maxnode
				node = "node#{i}"
				file.puts "tb-set-hardware $#{node} pcvm\n"
				file.puts "tb-set-node-os $#{node} OPENVZ-STD\n"
			end

			file.puts "\n"

			#file.puts "set nodeMonitor [$ns node]\n"
			#file.puts "tb-set-hardware $nodeMonitor pcvm\n"
			#file.puts "tb-set-node-os $nodeMonitor OPENVZ-STD\n"
			#file.puts "set progStartTcpdump [$nodeMonitor program-agent -command \"/proj/CONFINE/runme/virt/runme.monitorStartTcpdump\"]\n"
			#file.puts "set progStopTcpdump [$nodeMonitor program-agent -command \"/proj/CONFINE/runme/virt/runme.monitorStopTcpdump\"]\n"
			#file.puts "$monitorStartTcpdump add $progStartTcpdump\n"
    			#file.puts "$monitorStopTcpdump add $progStopTcpdump\n"
			#file.puts "append lanstr \"$nodeMonitor \"\n"
			#file.puts "\n"

			file.puts "set nodeMonitor [$ns node]\n"
			file.puts "tb-set-hardware $nodeMonitor pcvm\n"
			file.puts "tb-set-node-os $nodeMonitor OPENVZ-STD\n"

			file.puts "set progSetupEnv [$nodeMonitor program-agent -command \"/proj/CONFINE/runme-BMX6/virtual/setup_exp_env.sh\"]\n"
			file.puts "set progSetRouter [$nodeMonitor program-agent -command \"sudo /proj/CONFINE/runme-BMX6/virtual/setRouter.sh\"]\n"
			file.puts "set progFailPass [$nodeMonitor program-agent -command \"sudo /proj/CONFINE/runme-BMX6/virtual/failpass.sh #{@nodes.length}\"]\n"
			file.puts "set progStartTcpdump [$nodeMonitor program-agent -command \"/proj/CONFINE/runme-BMX6/virtual/start_tcpdump.sh\"]\n"
			file.puts "set progIntervalLog [$nodeMonitor program-agent -command \"/proj/CONFINE/runme-BMX6/virtual/start_interval_logging_special.sh\"]\n"
			file.puts "set progStopTcpdump [$nodeMonitor program-agent -command \"/proj/CONFINE/runme-BMX6/virtual/stop_tcpdump.sh\"]\n"
			
			file.puts "$monitorSetupEnv add $progSetupEnv\n"
			file.puts "$monitorSetRouter add $progSetRouter\n"
			file.puts "$monitorFailPass add $progFailPass\n"
			file.puts "$monitorStartTcpdump add $progStartTcpdump\n"
			file.puts "$monitorIntervalLog add $progIntervalLog\n"
    			file.puts "$monitorStopTcpdump add $progStopTcpdump\n"
			file.puts "append lanstr \"$nodeMonitor \"\n"
			file.puts "\n"

			file.puts "set nodePhysical [$ns node]\n"
			file.puts "tb-set-node-os $nodePhysical UBUNTU12-64-STD\n"
			file.puts "append lanstr \"$nodePhysical \"\n"
			file.puts "\n"

			file.puts "set big-lan [$ns make-lan \"$lanstr\" 100Mb 20ms]\n"
			file.puts "\n"
			
			#file.puts "$ns at 60 \"$nodeGroupFilter start\"\n"
			#file.puts "$ns at 120 \"$nodeGroupBMX6 start\"\n"
			#file.puts "$ns at 240 \"$monitorStartTcpdump start\"\n"
			#file.puts "$ns at 300 \"$monitorStopTcpdump start\"\n"

			file.puts "$ns at 30 \"$monitorSetupEnv start\"\n"
			file.puts "$ns at 40 \"$monitorSetRouter start\"\n"
			file.puts "$ns at 50 \"$nodeGroupInstall start\"\n"
			file.puts "$ns at 55 \"$nodeGroupInstallBMX6 start\"\n"
			file.puts "$ns at 180 \"$nodeGroupWriteIPv6 start\"\n"
			file.puts "$ns at 230 \"$monitorFailPass start\"\n"
			file.puts "$ns at 240 \"$nodeGroupFilter start\"\n"
			file.puts "$ns at 290 \"$nodeGroupRouteCheck start\"\n"
			file.puts "$ns at 300 \"$monitorStartTcpdump start\"\n"
			file.puts "$ns at 318 \"$monitorIntervalLog start\"\n"
			file.puts "$ns at 320 \"$nodeGroupBMX6 start\"\n"

			file.puts "# $ns at 540.0 \"$ns swapout\"\n"

			file.puts "\n"
			file.puts "$ns run"
		end	
	end

	def createGridBMX6NewNode(position)
		puts "New node BMX6 topology."
		# Create a new file and write to it
		t = Time.now
		gridName = t.strftime("GRID-BMX6-NEWNODE-#{(@dimension*@dimension)}-#{position}-%Y-%m-%d-%H-%M-%S")
		FileUtils.mkdir gridName
		filename = "#{gridName}/#{gridName}.ns"
		createFilters(gridName, false, true, position)
		File.open(filename, 'w') do |file|  
  			# use "\n" for two lines of text  
  			file.puts "set ns [new Simulator]\n"			
        		file.puts "source tb_compat.tcl\n\n"
			
			#file.puts "set nodeGroupFilter [$ns event-group]\n"
			#file.puts "set nodeGroupBMX6 [$ns event-group]\n"
			#file.puts "set monitorStartTcpdump [$ns event-group]\n"
			#file.puts "set monitorStopTcpdump [$ns event-group]\n\n"

			file.puts "set nodeGroupInstall [$ns event-group]\n"
			file.puts "set nodeGroupWriteIPv6 [$ns event-group]\n"
			file.puts "set nodeGroupFilter [$ns event-group]\n"
			file.puts "set nodeGroupRouteCheck [$ns event-group]\n"
			file.puts "set nodeGroupInstallBMX6 [$ns event-group]\n"
			file.puts "set nodeGroupBMX6 [$ns event-group]\n"
			file.puts "set nodeGroupStartAndRC [$ns event-group]\n"

			file.puts "set monitorSetupEnv [$ns event-group]\n"
			file.puts "set monitorSetRouter [$ns event-group]\n"
			file.puts "set monitorFailPass [$ns event-group]\n"
			file.puts "set monitorStartTcpdump [$ns event-group]\n"
			file.puts "set monitorStopTcpdump [$ns event-group]\n"
			file.puts "set monitorIntervalLog [$ns event-group]\n"

			maxnode = ((@dimension*@dimension) - 1)
			for i in 0..maxnode
				#node = "node#{i}"
				#@nodes.push node
				#file.puts "set #{node} [$ns node]\n"
				#file.puts "append lanstr \"$#{node} \"\n"
				#file.puts "set progStartFilter#{node} [$#{node} program-agent -command \"/proj/CONFINE/runme/virt/runme.vnodeStartFilter\"]\n"
				#file.puts "set progStartBMX6#{node} [$#{node} program-agent -command \"/proj/CONFINE/runme/virt/runme.vnodeStartBMX6\"]\n"
				#file.puts "$nodeGroupFilter add $progStartFilter#{node}\n"
				#file.puts "$nodeGroupBMX6 add $progStartBMX6#{node}\n\n"

				node = "#{i}"
				@nodes.push node
				file.puts "set node#{node} [$ns node]\n"
				# Automatically place BMX6 on the node (in dir /usr/local/src).
				file.puts "tb-set-node-tarfiles $node#{node} /usr/local/src/ /proj/CONFINE/tarfiles/bmx6.tar.gz"
				file.puts "append lanstr \"$node#{node} \"\n"

				file.puts "set progInstall#{node} [$node#{node} program-agent -command \"sudo /proj/CONFINE/runme-BMX6/virtual/install_ip6tables.sh\"]\n"
				file.puts "set progInstallBMX6#{node} [$node#{node} program-agent -command \"/proj/CONFINE/runme-BMX6/virtual/install_BMX6.sh\"]\n"
				file.puts "set progWriteIPv6#{node} [$node#{node} program-agent -command \"/proj/CONFINE/runme-BMX6/virtual/ipv6tofile.sh\"]\n"
				file.puts "set progFilter#{node} [$node#{node} program-agent -command \"/proj/CONFINE/runme-BMX6/virtual/filter_ip6tables.sh\"]\n"
				file.puts "set progRouteCheck#{node} [$node#{node} program-agent -command \"/proj/CONFINE/runme-BMX6/virtual/routeCheck.sh\"]\n"
				file.puts "set progBMX6#{node} [$node#{node} program-agent -command \"/proj/CONFINE/runme-BMX6/virtual/start_BMX6.sh\"]\n"
				file.puts "set progStartRCAddNode#{node} [$node#{node} program-agent -command \"/proj/CONFINE/runme-BMX6/virtual/start_rc_addnode.sh\"]\n"

				file.puts "$nodeGroupInstall add $progInstall#{node}\n"
				file.puts "$nodeGroupInstallBMX6 add $progInstallBMX6#{node}\n"
    				file.puts "$nodeGroupWriteIPv6 add $progWriteIPv6#{node}\n"
				file.puts "$nodeGroupFilter add $progFilter#{node}\n"
				file.puts "$nodeGroupRouteCheck add $progRouteCheck#{node}\n"
    				file.puts "$nodeGroupBMX6 add $progBMX6#{node}\n"
				file.puts "$nodeGroupStartAndRC add $progStartRCAddNode#{node}\n"
				file.puts "\n"
			end

			for i in 0..maxnode
				node = "node#{i}"
				file.puts "tb-set-hardware $#{node} pcvm\n"
				file.puts "tb-set-node-os $#{node} OPENVZ-STD\n"
			end

			file.puts "\n"


			node = "New"
			file.puts "set node#{node} [$ns node]\n"
			# Automatically place BMX6 on the node (in dir /usr/local/src).
			file.puts "tb-set-node-tarfiles $node#{node} /usr/local/src/ /proj/CONFINE/tarfiles/bmx6.tar.gz"
			file.puts "append lanstr \"$node#{node} \"\n"

			file.puts "set progInstall#{node} [$node#{node} program-agent -command \"sudo /proj/CONFINE/runme-BMX6/virtual/install_ip6tables.sh\"]\n"
			file.puts "set progInstallBMX6#{node} [$node#{node} program-agent -command \"/proj/CONFINE/runme-BMX6/virtual/install_BMX6.sh\"]\n"
			file.puts "set progWriteIPv6#{node} [$node#{node} program-agent -command \"/proj/CONFINE/runme-BMX6/virtual/ipv6tofile.sh\"]\n"
			file.puts "set progFilter#{node} [$node#{node} program-agent -command \"/proj/CONFINE/runme-BMX6/virtual/filter_ip6tables.sh\"]\n"
			file.puts "set progStartAndRC#{node} [$node#{node} program-agent -command \"/proj/CONFINE/runme-BMX6/virtual/start_and_rc_addnode.sh\"]\n"
			
			file.puts "$nodeGroupInstall add $progInstall#{node}\n"
			file.puts "$nodeGroupInstallBMX6 add $progInstallBMX6#{node}\n"
    			file.puts "$nodeGroupWriteIPv6 add $progWriteIPv6#{node}\n"
			file.puts "$nodeGroupFilter add $progFilter#{node}\n"
			file.puts "$nodeGroupStartAndRC add $progStartAndRC#{node}\n"

			file.puts "\n"

			node = "nodeNew"
			file.puts "tb-set-hardware $#{node} pcvm\n"
			file.puts "tb-set-node-os $#{node} OPENVZ-STD\n"
			file.puts "\n"

			file.puts "set nodeMonitor [$ns node]\n"
			file.puts "tb-set-hardware $nodeMonitor pcvm\n"
			file.puts "tb-set-node-os $nodeMonitor OPENVZ-STD\n"

			file.puts "set progSetupEnv [$nodeMonitor program-agent -command \"/proj/CONFINE/runme-BMX6/virtual/setup_exp_env.sh\"]\n"
			file.puts "set progSetRouter [$nodeMonitor program-agent -command \"sudo /proj/CONFINE/runme-BMX6/virtual/setRouter.sh\"]\n"
			file.puts "set progFailPass [$nodeMonitor program-agent -command \"sudo /proj/CONFINE/runme-BMX6/virtual/failpass.sh #{@nodes.length}\"]\n"
			#file.puts "set progStartTcpdump [$nodeMonitor program-agent -command \"/proj/CONFINE/runme-BMX6/virtual/start_tcpdump.sh\"]\n"
			file.puts "set progIntervalLog [$nodeMonitor program-agent -command \"/proj/CONFINE/runme-BMX6/virtual/start_interval_logging_special.sh\"]\n"
			#file.puts "set progStopTcpdump [$nodeMonitor program-agent -command \"/proj/CONFINE/runme-BMX6/virtual/stop_tcpdump.sh\"]\n"
			
			file.puts "$monitorSetupEnv add $progSetupEnv\n"
			file.puts "$monitorSetRouter add $progSetRouter\n"
			file.puts "$monitorFailPass add $progFailPass\n"
			#file.puts "$monitorStartTcpdump add $progStartTcpdump\n"
			file.puts "$monitorIntervalLog add $progIntervalLog\n"
    			#file.puts "$monitorStopTcpdump add $progStopTcpdump\n"
			file.puts "append lanstr \"$nodeMonitor \"\n"
			file.puts "\n"

			file.puts "set nodePhysical [$ns node]\n"
			file.puts "tb-set-node-os $nodePhysical UBUNTU12-64-STD\n"
			file.puts "append lanstr \"$nodePhysical \"\n"
			file.puts "\n"

			file.puts "set big-lan [$ns make-lan \"$lanstr\" 100Mb 20ms]\n"
			file.puts "\n"
			
			#file.puts "$ns at 60 \"$nodeGroupFilter start\"\n"
			#file.puts "$ns at 120 \"$nodeGroupBMX6 start\"\n"
			#file.puts "$ns at 240 \"$monitorStartTcpdump start\"\n"
			#file.puts "$ns at 300 \"$monitorStopTcpdump start\"\n"

			file.puts "$ns at 30 \"$monitorSetupEnv start\"\n"
			file.puts "$ns at 40 \"$monitorSetRouter start\"\n"
			file.puts "$ns at 50 \"$nodeGroupInstall start\"\n"
			file.puts "$ns at 55 \"$nodeGroupInstallBMX6 start\"\n"
			file.puts "$ns at 180 \"$nodeGroupWriteIPv6 start\"\n"
			file.puts "$ns at 230 \"$monitorFailPass start\"\n"
			file.puts "$ns at 240 \"$nodeGroupFilter start\"\n"
			file.puts "$ns at 290 \"$nodeGroupRouteCheck start\"\n"
			#file.puts "$ns at 300 \"$monitorStartTcpdump start\"\n"
			file.puts "$ns at 318 \"$monitorIntervalLog start\"\n"
			file.puts "$ns at 320 \"$nodeGroupBMX6 start\"\n"
			#file.puts "$ns at 500 \"$monitorStopTcpdump start\"\n"
			file.puts "$ns at 600 \"$nodeGroupStartAndRC start\"\n"

			file.puts "# $ns at 540.0 \"$ns swapout\"\n"

			file.puts "\n"
			file.puts "$ns run"
		end	
	end

	def createGridBMX6Reconvergence
		puts "Reconvergence BMX6 topology."
		# Create a new file and write to it
		t = Time.now
		gridName = t.strftime("GRID-BMX6-RECONVERGENCE-#{(@dimension*@dimension)}-%Y-%m-%d-%H-%M-%S")
		FileUtils.mkdir gridName
		filename = "#{gridName}/#{gridName}.ns"
		createFilters(gridName, true)
		File.open(filename, 'w') do |file|  
  			# use "\n" for two lines of text  
  			file.puts "set ns [new Simulator]\n"			
        		file.puts "source tb_compat.tcl\n\n"
			
			#file.puts "set nodeGroupFilter [$ns event-group]\n"
			#file.puts "set nodeGroupBMX6 [$ns event-group]\n"
			#file.puts "set monitorStartTcpdump [$ns event-group]\n"
			#file.puts "set monitorStopTcpdump [$ns event-group]\n\n"

			file.puts "set nodeGroupInstall [$ns event-group]\n"
			file.puts "set nodeGroupWriteIPv6 [$ns event-group]\n"
			file.puts "set nodeGroupFilter [$ns event-group]\n"
			file.puts "set nodeGroupRouteCheck [$ns event-group]\n"
			file.puts "set nodeGroupInstallBMX6 [$ns event-group]\n"
			file.puts "set nodeGroupBMX6 [$ns event-group]\n"
			file.puts "set nodeGroupStartReconv [$ns event-group]\n"

			file.puts "set monitorSetupEnv [$ns event-group]\n"
			file.puts "set monitorSetRouter [$ns event-group]\n"
			file.puts "set monitorFailPass [$ns event-group]\n"
			file.puts "set monitorStartTcpdump [$ns event-group]\n"
			file.puts "set monitorStopTcpdump [$ns event-group]\n"
			file.puts "set monitorIntervalLog [$ns event-group]\n"
			file.puts "\n"

			maxnode = ((@dimension*@dimension) - 1)
			for i in 0..maxnode
				#node = "node#{i}"
				#@nodes.push node
				#file.puts "set #{node} [$ns node]\n"
				#file.puts "append lanstr \"$#{node} \"\n"
				#file.puts "set progStartFilter#{node} [$#{node} program-agent -command \"/proj/CONFINE/runme/virt/runme.vnodeStartFilter\"]\n"
				#file.puts "set progStartBMX6#{node} [$#{node} program-agent -command \"/proj/CONFINE/runme/virt/runme.vnodeStartBMX6\"]\n"
				#file.puts "$nodeGroupFilter add $progStartFilter#{node}\n"
				#file.puts "$nodeGroupBMX6 add $progStartBMX6#{node}\n\n"

				node = "#{i}" 
				if (i == 0)
					node = "TL" # Top-left node.
				elsif (i == maxnode)
					node = "BR" # Bottom-right node.
				end
				@nodes.push node
				file.puts "set node#{node} [$ns node]\n"
				# Automatically place BMX6 on the node (in dir /usr/local/src).
				file.puts "tb-set-node-tarfiles $node#{node} /usr/local/src/ /proj/CONFINE/tarfiles/bmx6.tar.gz"
				file.puts "append lanstr \"$node#{node} \"\n"

				file.puts "set progInstall#{node} [$node#{node} program-agent -command \"sudo /proj/CONFINE/runme-BMX6/virtual/install_ip6tables.sh\"]\n"
				file.puts "set progInstallBMX6#{node} [$node#{node} program-agent -command \"/proj/CONFINE/runme-BMX6/virtual/install_BMX6.sh\"]\n"
				file.puts "set progWriteIPv6#{node} [$node#{node} program-agent -command \"/proj/CONFINE/runme-BMX6/virtual/ipv6tofile.sh\"]\n"
				file.puts "set progFilter#{node} [$node#{node} program-agent -command \"/proj/CONFINE/runme-BMX6/virtual/filter_ip6tables.sh\"]\n"
				file.puts "set progRouteCheck#{node} [$node#{node} program-agent -command \"/proj/CONFINE/runme-BMX6/virtual/routeCheck.sh\"]\n"
				file.puts "set progBMX6#{node} [$node#{node} program-agent -command \"/proj/CONFINE/runme-BMX6/virtual/start_BMX6.sh\"]\n"
				if (node == "TL")
					file.puts "set progStartReconv#{node} [$node#{node} program-agent -command \"/proj/CONFINE/runme-BMX6/virtual/start_reconv.sh nodeBR\"]\n"
					file.puts "$nodeGroupStartReconv add $progStartReconv#{node}\n"
				elsif (node == "BR")
					file.puts "set progStartReconv#{node} [$node#{node} program-agent -command \"/proj/CONFINE/runme-BMX6/virtual/start_reconv.sh nodeTL\"]\n"
					file.puts "$nodeGroupStartReconv add $progStartReconv#{node}\n"
				end

				file.puts "$nodeGroupInstall add $progInstall#{node}\n"
				file.puts "$nodeGroupInstallBMX6 add $progInstallBMX6#{node}\n"
    				file.puts "$nodeGroupWriteIPv6 add $progWriteIPv6#{node}\n"
				file.puts "$nodeGroupFilter add $progFilter#{node}\n"
				file.puts "$nodeGroupRouteCheck add $progRouteCheck#{node}\n"
    				file.puts "$nodeGroupBMX6 add $progBMX6#{node}\n"
				
				file.puts "\n"
			end

			for i in 0..maxnode
				node = "node#{i}"
				if (i == 0)
					node = "nodeTL" # Top-left node.
				elsif (i == maxnode)
					node = "nodeBR" # Bottom-right node.
				end
				file.puts "tb-set-hardware $#{node} pcvm\n"
				file.puts "tb-set-node-os $#{node} OPENVZ-STD\n"
			end

			file.puts "\n"

			#file.puts "set nodeMonitor [$ns node]\n"
			#file.puts "tb-set-hardware $nodeMonitor pcvm\n"
			#file.puts "tb-set-node-os $nodeMonitor OPENVZ-STD\n"
			#file.puts "set progStartTcpdump [$nodeMonitor program-agent -command \"/proj/CONFINE/runme/virt/runme.monitorStartTcpdump\"]\n"
			#file.puts "set progStopTcpdump [$nodeMonitor program-agent -command \"/proj/CONFINE/runme/virt/runme.monitorStopTcpdump\"]\n"
			#file.puts "$monitorStartTcpdump add $progStartTcpdump\n"
    			#file.puts "$monitorStopTcpdump add $progStopTcpdump\n"
			#file.puts "append lanstr \"$nodeMonitor \"\n"
			#file.puts "\n"

			file.puts "set nodeMonitor [$ns node]\n"
			file.puts "tb-set-hardware $nodeMonitor pcvm\n"
			file.puts "tb-set-node-os $nodeMonitor OPENVZ-STD\n"

			file.puts "set progSetupEnv [$nodeMonitor program-agent -command \"/proj/CONFINE/runme-BMX6/virtual/setup_exp_env.sh\"]\n"
			file.puts "set progSetRouter [$nodeMonitor program-agent -command \"sudo /proj/CONFINE/runme-BMX6/virtual/setRouter.sh\"]\n"
			file.puts "set progFailPass [$nodeMonitor program-agent -command \"sudo /proj/CONFINE/runme-BMX6/virtual/failpass.sh #{@nodes.length}\"]\n"
			#file.puts "set progStartTcpdump [$nodeMonitor program-agent -command \"/proj/CONFINE/runme-BMX6/virtual/start_tcpdump.sh\"]\n"
			file.puts "set progIntervalLog [$nodeMonitor program-agent -command \"/proj/CONFINE/runme-BMX6/virtual/start_interval_logging_special.sh\"]\n"
			#file.puts "set progStopTcpdump [$nodeMonitor program-agent -command \"/proj/CONFINE/runme-BMX6/virtual/stop_tcpdump.sh\"]\n"
			
			file.puts "$monitorSetupEnv add $progSetupEnv\n"
			file.puts "$monitorSetRouter add $progSetRouter\n"
			file.puts "$monitorFailPass add $progFailPass\n"
			#file.puts "$monitorStartTcpdump add $progStartTcpdump\n"
			file.puts "$monitorIntervalLog add $progIntervalLog\n"
    			#file.puts "$monitorStopTcpdump add $progStopTcpdump\n"
			file.puts "append lanstr \"$nodeMonitor \"\n"
			file.puts "\n"

			file.puts "set nodePhysical [$ns node]\n"
			file.puts "tb-set-node-os $nodePhysical UBUNTU12-64-STD\n"
			file.puts "append lanstr \"$nodePhysical \"\n"
			file.puts "\n"

			file.puts "set big-lan [$ns make-lan \"$lanstr\" 100Mb 20ms]\n"
			file.puts "\n"
			
			#file.puts "$ns at 60 \"$nodeGroupFilter start\"\n"
			#file.puts "$ns at 120 \"$nodeGroupBMX6 start\"\n"
			#file.puts "$ns at 240 \"$monitorStartTcpdump start\"\n"
			#file.puts "$ns at 300 \"$monitorStopTcpdump start\"\n"

			file.puts "$ns at 30 \"$monitorSetupEnv start\"\n"
			file.puts "$ns at 40 \"$monitorSetRouter start\"\n"
			file.puts "$ns at 50 \"$nodeGroupInstall start\"\n"
			file.puts "$ns at 55 \"$nodeGroupInstallBMX6 start\"\n"
			file.puts "$ns at 180 \"$nodeGroupWriteIPv6 start\"\n"
			file.puts "$ns at 230 \"$monitorFailPass start\"\n"
			file.puts "$ns at 240 \"$nodeGroupFilter start\"\n"
			file.puts "$ns at 290 \"$nodeGroupRouteCheck start\"\n"
			#file.puts "$ns at 300 \"$monitorStartTcpdump start\"\n"
			file.puts "$ns at 318 \"$monitorIntervalLog start\"\n"
			file.puts "$ns at 320 \"$nodeGroupBMX6 start\"\n"
			#file.puts "$ns at 500 \"$monitorStopTcpdump start\"\n"
			file.puts "$ns at 580 \"$nodeGroupStartReconv start\"\n"

			file.puts "# $ns at 540.0 \"$ns swapout\"\n"

			file.puts "\n"
			file.puts "$ns run"
		end	
	end
end



protocol = ARGV[0]
typeOfTopology = ARGV[1]
dim = Integer(ARGV[2])

nsgrid = NSGrid.new dim

if (protocol == "bmx")
	if (typeOfTopology == "def")
		nsgrid.createGridBMX6
	elsif (typeOfTopology == "new")
		position = ARGV[3]
		nsgrid.createGridBMX6NewNode position
	elsif (typeOfTopology == "reconv")
		nsgrid.createGridBMX6Reconvergence
	else
		puts "Wrong type of topology."
	end
elsif (protocol == "olsr")
	if (typeOfTopology == "def")
		nsgrid.createGridOLSRd
	elsif (typeOfTopology == "new")
		position = ARGV[3]
		nsgrid.createGridOLSRdNewNode position
	elsif (typeOfTopology == "reconv")
		nsgrid.createGridOLSRdReconvergence
	else
		puts "Wrong type of topology."
	end
else
	puts "Wrong protocol."
end
