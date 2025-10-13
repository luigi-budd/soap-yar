return function(v, ML)
	local dup = v.dupx()
	v.drawScaled(
		ML.client.mouse_x,
		ML.client.mouse_y,
		FU / dup,
		v.cachePatch(ML.client.canPressSomething and "ML_RBLX_POINT" or "ML_RBLX_CURS"),
		0
	)
end, nil, true