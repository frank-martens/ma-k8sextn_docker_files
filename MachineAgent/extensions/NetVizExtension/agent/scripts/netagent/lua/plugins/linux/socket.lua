--[[
 * Copyright (c) AppDynamics, Inc., and its affiliates
 * 2015
 * All Rights Reserved
 * THIS IS UNPUBLISHED PROPRIETARY CODE OF APPDYNAMICS, INC.
 * The copyright notice above does not evidence any actual or intended
 * publication of such source code
--]]

package.path = '../../?.lua;' .. package.path
require "helper"
require "metric-properties"

local socket_module = {}

est_key = "Established"
tw_key = "TimeWait"
embryonic_key = "Embryonic"
wait_key = "Wait"

-- Metric metdadata table
-- Used for populating metrics
socket_md_tbl = {
	{	-- Established
		m_name = est_key,
		m_type = metric_type.mt_avg,
		m_dmm_mode = dmm_mode.dmm_kpi,
		m_time_roll = time_rollup.tr_avg,
		m_cluster_roll = cluster_rollup.cr_coll,
		m_agg_roll = agg_rollup.ar_avg,
	},
	{	-- TimeWait
		m_name = tw_key,
		m_type = metric_type.mt_avg,
		m_dmm_mode = dmm_mode.dmm_kpi,
		m_time_roll = time_rollup.tr_avg,
		m_cluster_roll = cluster_rollup.cr_coll,
		m_agg_roll = agg_rollup.ar_avg,
	},
	{	-- Embryonic
		m_name = embryonic_key,
		m_type = metric_type.mt_avg,
		m_dmm_mode = dmm_mode.dmm_kpi,
		m_time_roll = time_rollup.tr_avg,
		m_cluster_roll = cluster_rollup.cr_coll,
		m_agg_roll = agg_rollup.ar_avg,
	},
	{	-- Wait
		m_name = wait_key,
		m_type = metric_type.mt_avg,
		m_dmm_mode = dmm_mode.dmm_kpi,
		m_time_roll = time_rollup.tr_avg,
		m_cluster_roll = cluster_rollup.cr_coll,
		m_agg_roll = agg_rollup.ar_avg,
	},
}


--[[
-- Helper table for computing the socket metrics.
-- This is the data used by the metrics function for performing
-- the metrics computation.
--]]
socket_metrics_data = {
	{metric = "Established", input = {"ESTAB"}},
	{metric = "TimeWait", input = {"TIME-WAIT"}},
	{metric = "Embryonic", input = {"SYN-SENT", "SYN-RECV"}},
	{metric = "Wait", input = {"FIN-WAIT-1", "FIN-WAIT-2",
		"TIME-WAIT", "CLOSE-WAIT", "CLOSING"}},
}


--[[
-- Data structure holding all information for statistics collection
--]]
socket_statistics_ds = {
	command = "ss -tna | grep -v State | awk '{print $1}' | sort | uniq -c",
	data = socket_statistics_data,
}


--[[
-- Callback function called by application to gather statistics data.
--]]
function socket_statistics_fn()
	local _table = socket_statistics_ds
	local _val_table = {}
	local _count = 0
	local _op = run_command(_table.command)

	if (_op == nil) then return nil end

	for line in multi_line_iter(_op) do
		_, _, num, sock_type = string.find(line, "%s*(%d+)%s*(%g+)")
		if num ~= nil and sock_type ~= nil then
			_val_table[sock_type] = num
		end
	end

	return _val_table
end


--[[
-- Callback function called by application to gather metrics data.
--]]
function socket_metrics_fn()
	local _val_table = {}
	local stats_table = socket_statistics_fn()

	if (stats_table == nil) then return nil end

	for _, _v1 in pairs(socket_metrics_data) do
		for _, _v2 in pairs(_v1.input) do
			if (_val_table[_v1.metric] == nil) then
				_val_table[_v1.metric] = 0
			end

			if (stats_table[_v2] ~= nil) then
				_val_table[_v1.metric] =
				_val_table[_v1.metric] +
				    stats_table[_v2]
			end
		end
	end

	return _val_table
end


--[[
-- Plugin initialization function.
-- Just returns a table as required by the plugin infrastructure.
--]]
function plugin_init()
	return {
		-- Plugin info.
		plugin_name = "Socket",
		plugin_type = "monitoring",

		-- Metrics info.
		metrics_md = "socket_md_tbl",
		metrics_cb = "socket_metrics_fn",
	}
end


--[[
-- Plugin finish function. Nothing to do for now.
--]]
function plugin_fini()
	return
end

socket_module.plugin_init = plugin_init
socket_module.plugin_fini = plugin_fini

return socket_module
