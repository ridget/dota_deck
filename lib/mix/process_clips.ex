defmodule Mix.Tasks.ProcessClips do
  use Mix.Task

  @shortdoc "Process audio clips for transcription and embedding"

  def run(_args) do
    # Ensure your app and dependencies are started
    Mix.Task.run("app.start")

    # Start a supervisor for our audio transcription pipeline
    {:ok, _sup_pid} = DotaDeck.PipelineSupervisor.start_link(defn_options: [compiler: EXLA])

    # Load audio files from priv directory
    audio_paths = Path.wildcard("priv/audio/*.mp3")

    # Call your pipeline function (replace with your actual module)
    DotaDeck.ClipPipeline.process_clips(audio_paths)
  end
end
