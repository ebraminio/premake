--
-- vs2005_solution.lua
-- Generate a Visual Studio 2005-2012 solution.
-- Copyright (c) 2009-2012 Jason Perkins and the Premake project
--

	premake.vstudio.sln2005 = { }
	local vstudio = premake.vstudio
	local sln2005 = premake.vstudio.sln2005
	local solution = premake.solution
	local project = premake5.project


--
-- Generate a Visual Studio 200x solution, with support for the new platforms API.
--

	function sln2005.generate_ng(sln)
		io.eol = '\r\n'
		
		-- Mark the file as Unicode
		_p('\239\187\191')

		sln2005.header(sln)

		for prj in premake.solution.eachproject_ng(sln) do
			sln2005.project_ng(prj)
		end

		_p('Global')
		sln2005.solutionConfigurationPlatforms(sln)
		sln2005.projectConfigurationPlatforms(sln)
		sln2005.properties(sln)
		_p('EndGlobal')
	end


--
-- Generate the solution header
--

	function sln2005.header(sln)
		local version = { 
			vs2005 = 9, 
			vs2008 = 10, 
			vs2010 = 11, 
			vs2012 = 12,
		}
		_p('Microsoft Visual Studio Solution File, Format Version %d.00', version[_ACTION])
		_p('# Visual Studio %s', _ACTION:sub(3))
	end


--
-- Write out an entry for a project
--

	function sln2005.project_ng(prj)
		-- Build a relative path from the solution file to the project file
		local slnpath = premake.solution.getlocation(prj.solution)
		local prjpath = vstudio.projectfile_ng(prj)
		prjpath = path.translate(path.getrelative(slnpath, prjpath))
		
		_x('Project("{%s}") = "%s", "%s", "{%s}"', vstudio.tool(prj), prj.name, prjpath, prj.uuid)
		if _ACTION < "vs2012" then
			sln2005.projectdependencies_ng(prj)
		end
		_p('EndProject')
	end


--
-- Write out the list of project dependencies for a particular project.
--

	function sln2005.projectdependencies_ng(prj)
		local deps = project.getdependencies(prj)
		if #deps > 0 then
			_p(1,'ProjectSection(ProjectDependencies) = postProject')
			for _, dep in ipairs(deps) do
				_p(2,'{%s} = {%s}', dep.uuid, dep.uuid)
			end
			_p(1,'EndProjectSection')
		end
	end


--
-- Write out the contents of the SolutionConfigurationPlatforms section, which
-- lists all of the configuration/platform pairs that exist in the solution.
--

	function sln2005.solutionConfigurationPlatforms(sln)
		_p(1,'GlobalSection(SolutionConfigurationPlatforms) = preSolution')
		for cfg in solution.eachconfig(sln) do
			local platforms = sln2005.getcfgplatforms(sln, cfg)
			for _, platform in ipairs(platforms) do
				_p(2,'%s|%s = %s|%s', cfg.buildcfg, platform, cfg.buildcfg, platform)
			end
		end
		_p(1,'EndGlobalSection')
	end


--
-- Write out the contents of the ProjectConfigurationPlatforms section, which maps
-- the configuration/platform pairs into each project of the solution.
--

	function sln2005.projectConfigurationPlatforms(sln)
		_p(1,'GlobalSection(ProjectConfigurationPlatforms) = postSolution')
		for prj in solution.eachproject_ng(sln) do
			for slncfg in solution.eachconfig(sln) do
				local prjcfg = project.getconfig(prj, slncfg.buildcfg, slncfg.platform)
				if prjcfg then
					local slnplatform = vstudio.platform(slncfg)
					local prjplatform = vstudio.projectplatform(prjcfg)
					local architecture = vstudio.architecture(prjcfg)
					
					_p(2,'{%s}.%s|%s.ActiveCfg = %s|%s', prj.uuid, slncfg.buildcfg, slnplatform, prjplatform, architecture)
					_p(2,'{%s}.%s|%s.Build.0 = %s|%s', prj.uuid, slncfg.buildcfg, slnplatform, prjplatform, architecture)
				end
			end		
		end
		_p(1,'EndGlobalSection')
	end


--
-- Write out contents of the SolutionProperties section; currently unused.
--

	function sln2005.properties(sln)	
		_p('\tGlobalSection(SolutionProperties) = preSolution')
		_p('\t\tHideSolutionNode = FALSE')
		_p('\tEndGlobalSection')
	end


--
-- Return a list of required platforms for a specific configuration. 
-- Depending on mix of languages used by the solution, a configuration
-- may need multiple platforms listed.
--
-- @param sln
--    The current solution.
-- @param cfg
--    The configuration to query.
-- @return
--    A array of one or more platform identifiers.
--

	function sln2005.getcfgplatforms(sln, cfg)
		local r = {}

		local hasdotnet = solution.hasdotnetproject(sln)
		local hascpp = solution.hascppproject(sln)
		local is2010 = _ACTION > "vs2008"
		
		if hasdotnet then
			if not hascpp or not is2010 then
				table.insert(r, "Any CPU")
			end
			if hascpp or is2010 then
				table.insert(r, "Mixed Platforms")
			end
		end

		if cfg.platform then
			table.insert(r, cfg.platform)
		else
			if hascpp or not is2010 then
				table.insert(r, "Win32")
			end
			if hasdotnet and is2010 then
				table.insert(r, "x86")
			end
		end
		
		return r
	end



-----------------------------------------------------------------------------
-- Everything below this point is a candidate for deprecation
-----------------------------------------------------------------------------

--
-- Entry point; creates the solution file.
--

	function sln2005.generate(sln)
		io.eol = '\r\n'

		-- Precompute Visual Studio configurations
		sln.vstudio_configs = premake.vstudio.buildconfigs(sln)
		
		-- Mark the file as Unicode
		_p('\239\187\191')

		sln2005.header(sln)

		for prj in premake.solution.eachproject(sln) do
			sln2005.project(prj)
		end

		_p('Global')
		sln2005.platforms(sln)
		sln2005.project_platforms(sln)
		sln2005.properties(sln)
		_p('EndGlobal')
	end


--
-- Write out an entry for a project
--

	function sln2005.project(prj)
		-- Build a relative path from the solution file to the project file
		local projpath = path.translate(path.getrelative(prj.solution.location, vstudio.projectfile(prj)), "\\")
			
		_p('Project("{%s}") = "%s", "%s", "{%s}"', vstudio.tool(prj), prj.name, projpath, prj.uuid)
		sln2005.projectdependencies(prj)
		_p('EndProject')
	end


--
-- Write out the list of project dependencies for a particular project.
--

	function sln2005.projectdependencies(prj)
		local deps = premake.getdependencies(prj)
		if #deps > 0 then
			_p('\tProjectSection(ProjectDependencies) = postProject')
			for _, dep in ipairs(deps) do
				_p('\t\t{%s} = {%s}', dep.uuid, dep.uuid)
			end
			_p('\tEndProjectSection')
		end
	end


--
-- Write out the contents of the SolutionConfigurationPlatforms section, which
-- lists all of the configuration/platform pairs that exist in the solution.
--

	function sln2005.platforms(sln)
		_p('\tGlobalSection(SolutionConfigurationPlatforms) = preSolution')
		for _, cfg in ipairs(sln.vstudio_configs) do
			_p('\t\t%s = %s', cfg.name, cfg.name)
		end
		_p('\tEndGlobalSection')
	end
	
	

--
-- Write out the contents of the ProjectConfigurationPlatforms section, which maps
-- the configuration/platform pairs into each project of the solution.
--

	function sln2005.project_platforms(sln)
		_p('\tGlobalSection(ProjectConfigurationPlatforms) = postSolution')
		for prj in premake.solution.eachproject(sln) do
			for _, cfg in ipairs(sln.vstudio_configs) do
			
				-- .NET projects always map to the "Any CPU" platform (for now, at 
				-- least). For C++, "Any CPU" and "Mixed Platforms" map to the first
				-- C++ compatible target platform in the solution list.
				local mapped
				if premake.isdotnetproject(prj) then
					mapped = "Any CPU"
				else
					if cfg.platform == "Any CPU" or cfg.platform == "Mixed Platforms" then
						mapped = sln.vstudio_configs[3].platform
					else
						mapped = cfg.platform
					end
				end

				_p('\t\t{%s}.%s.ActiveCfg = %s|%s', prj.uuid, cfg.name, cfg.buildcfg, mapped)
				if mapped == cfg.platform or cfg.platform == "Mixed Platforms" then
					_p('\t\t{%s}.%s.Build.0 = %s|%s',  prj.uuid, cfg.name, cfg.buildcfg, mapped)
				end
			end
		end
		_p('\tEndGlobalSection')
	end
