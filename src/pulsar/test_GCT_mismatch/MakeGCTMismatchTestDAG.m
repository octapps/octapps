function MakeGCTMismatchTestDAG(varargin)

  ## parse options
  parseOptions(varargin,
               {"run_ID", "char"},
               {"num_injections", "numeric,scalar", 1000},
               {"SFT_timestamps_H1", "char"},
               {"SFT_timestamps_L1", "char"},
               {"GCT_segments", "char"},
               {"false_alarm", "numeric,scalar", 0.01},
               {"false_dismissal", "numeric,scalar", 0.1},
               {"signal_only", "logical,scalar", true},
               {"f1dot_band", "numeric,scalar", 1e-8},
               {"f2dot_band", "numeric,scalar", 0.0},
               {"debug_level", "numeric,scalar", 0},
               {"jobs_directory", "char", pwd},
               {"logs_directory", "char", getenv("LOCALHOME")},
               {"job_retries", "numeric,scalar", 5}
               );
  SFT_timestamps = struct;
  SFT_timestamps.H1 = SFT_timestamps_H1;
  SFT_timestamps.L1 = SFT_timestamps_L1;
  IFOs = fieldnames(SFT_timestamps);
  rundir = fullfile(jobs_directory, run_ID);

  ## check input
  if !exist(jobs_directory, "dir")
    error("%s: directory '%s' does not exist", funcName, jobs_directory);
  endif    
  if !exist(logs_directory, "dir")
    error("%s: directory '%s' does not exist", funcName, logs_directory);
  endif    
  if exist(rundir, "dir")
    error("%s: directory '%s' already exists", funcName, rundir);
  endif    
  for i = 1:length(IFOs)
    if !exist(SFT_timestamps.(IFOs{i}), "file")
      error("%s: file '%s' does not exist", funcName, SFT_timestamps.(IFOs{i}));
    endif
  endfor
  if !exist(GCT_segments, "file")
    error("%s: file '%s' does not exist", funcName, GCT_segments);
  endif

  ## check environment
  if isempty(getenv("LAL_DATA_PATH"))
    error("%s: set $LAL_DATA_PATH to LAL data search path", funcName);
  endif

  ## find required lalapps programs
  progs = {"Makefakedata_v4", "getMesh", "HierarchSearchGCT"};
  for i = 1:length(progs)
    if isempty(file_in_path(getenv("PATH"), strcat("lalapps_", progs{i})))
      error("%s: could not find 'lalapps_%s'", funcName, progs{i});
    endif
  endfor

  ## find injection script
  injection_script = file_in_loadpath("TestGCTMismatch.m");
  if isempty(injection_script)
    error("%s: cannot find injection script 'TestGCTMismatch.m'", funcName);
  endif

  ## get number and average segment duration
  ## assume equal amount of data from each IFO
  segs = load(GCT_segments);
  Tsegs = segs(:,3) / 24;  # convert from hours to days
  Tseg = mean(Tsegs);
  Nseg = length(Tsegs) * length(IFOs);

  ## get start and end times
  startTime = segs(1,1);
  endTime = segs(end,2);
  
  ## calculate signal strength needed for required false alarm/dismissal
  rho = AnalyticSensitivitySNRChiSqr(false_alarm, false_dismissal, Nseg, 4);
  Sh = 1.0;
  h0 = 2.5 * sqrt(Sh / Tseg) * rho;
  if signal_only
    Sh = 0.0;
  endif

  ## make directories
  mkdir(jobs_directory);
  mkdir(rundir);

  ## create job description
  job = struct;
  job.universe = "vanilla";
  job.initialdir = rundir;
  job.executable = fullfile(octave_config_info("bindir"), "octave");
  job.output = "stdout.$(cluster)";
  job.error = "stderr.$(cluster)";
  job.log = fullfile(logs_directory, sprintf("GCTMismatchTest_%s.log", run_ID));
  job.environment = {"OCTAVE_PATH", "PATH", "LD_LIBRARY_PATH", "LAL_DATA_PATH"};
  job.queue = 1;

  ## create job arguments
  job.arguments = struct;
  job.arguments.__preamble = cstrcat("-qfH ", injection_script);
  SFT_timestamps_str = "struct(";
  for i = 1:length(IFOs)
    if i > 1
      SFT_timestamps_str = strcat(SFT_timestamps_str, ",");
    endif
    SFT_timestamps_str = strcat(SFT_timestamps_str, sprintf("\"%s\",\"%s\"", IFOs{i}, SFT_timestamps.(IFOs{i})));
  endfor
  SFT_timestamps_str = strcat(SFT_timestamps_str, ")");
  job.arguments.SFT_timestamps = SFT_timestamps_str;
  job.arguments.GCT_segments = GCT_segments;
  job.arguments.start_time = startTime;
  job.arguments.end_time = endTime;
  job.arguments.Sh = Sh;
  job.arguments.h0 = h0;
  job.arguments.f1dot_band = f1dot_band;
  job.arguments.f2dot_band = f2dot_band;
  job.arguments.debug_level = debug_level;
  job.arguments.result_file = "results.$(cluster)";

  ## specify files to be transferred to/from submit machine
  job.should_transfer_files = "yes";
  job.when_to_transfer_output = "on_exit";
  job.transfer_input_files = {canonicalize_file_name(GCT_segments)};
  for i = 1:length(IFOs)
    job.transfer_input_files{end+1} = canonicalize_file_name(SFT_timestamps.(IFOs{i}));
  endfor
  job.transfer_output_files = "results.$(cluster)";

  ## create job submission file
  jobfile = fullfile(rundir, "condor.job");
  makeCondorJob(jobfile, job);

  ## create DAG
  DAG = struct;
  for i = 1:num_injections
    DAG(i).jobname = sprintf("%s_%i", run_ID, i);
    DAG(i).jobfile = jobfile;
    DAG(i).retry = job_retries;
  endfor

  ## create DAG file
  dagfile = fullfile(rundir, "condor.dag");
  makeCondorDAG(dagfile, DAG);

endfunction

## if running as a script
if runningAsScript
  MakeGCTMismatchTestDAG(parseCommandLine(){:});
endif
