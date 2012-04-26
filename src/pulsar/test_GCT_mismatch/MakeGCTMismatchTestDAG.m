## Copyright (C) 2012 Karl Wette
##
## This program is free software; you can redistribute it and/or modify
## it under the terms of the GNU General Public License as published by
## the Free Software Foundation; either version 2 of the License, or
## (at your option) any later version.
##
## This program is distributed in the hope that it will be useful,
## but WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
## GNU General Public License for more details.
##
## You should have received a copy of the GNU General Public License
## along with with program; see the file COPYING. If not, write to the
## Free Software Foundation, Inc., 59 Temple Place, Suite 330, Boston,
## MA  02111-1307  USA

## Make a DAG for performing injection testing of HierarchSearchGCT
##
## Options:
## - run_ID: unique ID for creating DAG-related files/directories
## - num_injections: number of injections to perform
## - SFT_timestamps_H1: timestamps of H1 SFTs
## - SFT_timestamps_L1: timestamps of L1 SFTs
## - GCT_segments: segment list to give the GCT code
## - false_alarm: target false alarm rate in S=1.0 noise
## - false_dismissal: target false dismissal rate in S=1.0 noise
## - signal_only: do not add noise to SFTs
## - freq: frequency at which to inject/search over
## - f1dot_band: 1st spindown band to inject/search over
## - f2dot_inj_band: 2nd spindown band to inject over
## - f2dot_sch_band: 2nd spindown band to search over
## - debug_level: set debug level of LAL codes
## - jobs_directory: base directory where DAG directory is created
## - logs_directory: base directory where DAG logs are created
## - job_retries: how many times DAG should retry injection jobs

function MakeGCTMismatchTestDAG(varargin)

  ## parse options
  parseOptions(varargin,
               {"run_ID", "char"},
               {"num_injections", "numeric,scalar"},
               {"SFT_timestamps_H1", "char"},
               {"SFT_timestamps_L1", "char"},
               {"GCT_segments", "char"},
               {"false_alarm", "numeric,scalar", 0.01},
               {"false_dismissal", "numeric,scalar", 0.1},
               {"signal_only", "logical,scalar", true},
               {"freq", "numeric,scalar"},
               {"f1dot_band", "numeric,scalar"},
               {"f2dot_inj_band", "numeric,scalar"},
               {"f2dot_sch_band", "numeric,scalar"},
               {"f2dot_refine", "numeric,scalar"},
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

  ## get number and average segment duration
  ## assume equal amount of data from each IFO
  segs = load(GCT_segments);
  Tsegs = segs(:,3) * 3600;  # convert from hours to seconds
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

  ## install octapps
  install_directory = make_absolute_filename(fullfile(rundir, "local"));
  octapps_install(install_directory);

  ## write bootscript
  bootscript_name = "TestGCTMismatch.sh";
  bootscript_path = fullfile(rundir, bootscript_name);
  fid = fopen(bootscript_path, "w");
  if fid < 0
    error("%s: failed to open %s", funcName, bootscript_path);
  endif
  fprintf(fid, "#!/bin/bash\n");
  fprintf(fid, "source %s/etc/lalpulsar-user-env.sh\n", install_directory);
  fprintf(fid, "source %s/etc/lalapps-user-env.sh\n", install_directory);
  fprintf(fid, "source %s/etc/octapps-user-env.sh\n", install_directory);
  fprintf(fid, "exec octapps_run TestGCTMismatch \"$@\"\n");
  fclose(fid);
  status = system(cstrcat("chmod +x ", bootscript_path));
  if status != 0
    error("%s: failed to make %s executable", funcName, bootscript_path);
  endif

  ## create job description
  job = struct;
  job.universe = "vanilla";
  job.request_memory = "400"; # MB
  job.initialdir = rundir;
  job.executable = bootscript_path;
  job.output = "condor.out.$(jobindex)";
  job.error = "condor.err.$(jobindex)";
  job.log = fullfile(logs_directory, sprintf("GCTMismatchTest_%s.log", run_ID));
  job.queue = 1;

  ## create job arguments
  job.arguments = struct;
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
  job.arguments.Tseg = Tseg;
  job.arguments.freq = freq;
  job.arguments.f1dot_band = f1dot_band;
  job.arguments.f2dot_inj_band = f2dot_inj_band;
  job.arguments.f2dot_sch_band = f2dot_sch_band;
  job.arguments.f2dot_refine = f2dot_refine;
  job.arguments.debug_level = debug_level;
  job.arguments.result_file = "results.$(jobindex)";

  ## specify files to be transferred to/from submit machine
  job.should_transfer_files = "yes";
  job.when_to_transfer_output = "on_exit";
  job.transfer_input_files = {canonicalize_file_name(GCT_segments)};
  for i = 1:length(IFOs)
    job.transfer_input_files{end+1} = canonicalize_file_name(SFT_timestamps.(IFOs{i}));
  endfor
  job.transfer_output_files = "results.$(jobindex)";

  ## create job submission file
  jobfile = fullfile(rundir, "condor.job");
  makeCondorJob(jobfile, job);

  ## create DAG
  DAG = struct;
  for i = 1:num_injections
    DAG(i).jobname = sprintf("%s_%i", run_ID, i);
    DAG(i).jobfile = jobfile;
    DAG(i).vars.jobindex = sprintf("%i", i);
    DAG(i).retry = job_retries;
  endfor

  ## create DAG file
  dagfile = fullfile(rundir, "condor.dag");
  makeCondorDAG(dagfile, DAG);

  ## save all variables used in creating the DAG
  save(strcat(run_ID, "_dag.dat"));

endfunction
