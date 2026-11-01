extends "res://tools/benchmark_visual_polish.gd"
## Same paired scenarios, with viewport render timings and an unsorted frame trace.
## GPU timings may lag CPU observations; these are observations, not synchronized spans.
## Performance process/physics monitors refresh less often than frames. Zero-only GPU
## timings are marked unavailable; they do not mean rendering was free.
func _initialize() -> void:
	report_path = "res://build/visual-polish-timing.json"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--report="): report_path = "res://build/" + arg.trim_prefix("--report=") + ".json"
	if "--no-vsync" in OS.get_cmdline_user_args(): DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	super._initialize()

func distribution(values: Array) -> Dictionary:
	var sorted = values.duplicate(); sorted.sort()
	return {"median": sorted[sorted.size()/2], "p95": sorted[mini(sorted.size()-1, ceili(sorted.size()*.95)-1)], "p99": sorted[mini(sorted.size()-1, ceili(sorted.size()*.99)-1)], "max": sorted.back()}

func sample(camera: Camera3D, origin: Vector3, eye: Vector3, target: Vector3, animate: Callable = Callable(), seconds: float = 5.0) -> Dictionary:
	# Diagnostic controls affect only this isolated process, never saved settings.
	if "--no-shadows" in OS.get_cmdline_user_args():
		for light in root.find_children("*", "Light3D", true, false): light.shadow_enabled=false
	var viewport := camera.get_viewport().get_viewport_rid()
	RenderingServer.viewport_set_measure_render_time(viewport, true)
	camera.position=origin+eye; camera.look_at(origin+target)
	var warmup:=Time.get_ticks_usec()
	while Time.get_ticks_usec()-warmup<2000000:
		if animate.is_valid(): animate.call((Time.get_ticks_usec()-warmup)/1000000.0)
		await process_frame
	var trace: Array=[]; var times: Array=[]; var cpu: Array=[]; var gpu: Array=[]; var process: Array=[]; var physics: Array=[]; var draws: Array=[]
	var started:=Time.get_ticks_usec(); var previous:=started
	while Time.get_ticks_usec()-started<int(seconds*1000000):
		if animate.is_valid(): animate.call((Time.get_ticks_usec()-warmup)/1000000.0)
		await process_frame
		var now:=Time.get_ticks_usec()
		var interval: float=(now-previous)/1000.0; previous=now
		var render_cpu:=RenderingServer.viewport_get_measured_render_time_cpu(viewport)
		var render_gpu:=RenderingServer.viewport_get_measured_render_time_gpu(viewport)
		var process_ms:=Performance.get_monitor(Performance.TIME_PROCESS)*1000
		var physics_ms:=Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS)*1000
		var draw_count:=Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
		times.append(interval); cpu.append(render_cpu); gpu.append(render_gpu); process.append(process_ms); physics.append(physics_ms); draws.append(draw_count)
		trace.append([snappedf((now-started)/1000000.0,.0001),interval,render_cpu,render_gpu,process_ms,physics_ms,draw_count])
	assert(times.size()>10)
	var wall:=distribution(times)
	return {"frames":times.size(),"median_ms":wall.median,"p95_ms":wall.p95,"p99_ms":wall.p99,"render_cpu_ms":distribution(cpu),"render_gpu_ms":distribution(gpu),"gpu_timer_available":gpu.max()>0,"vsync":DisplayServer.window_get_vsync_mode(),"shadows_disabled":"--no-shadows" in OS.get_cmdline_user_args(),"process_ms":distribution(process),"physics_ms":distribution(physics),"draw_calls":distribution(draws),"trace_columns":["elapsed_s","wall_ms","render_cpu_ms","render_gpu_ms","process_ms","physics_ms","draw_calls"],"trace":trace}
