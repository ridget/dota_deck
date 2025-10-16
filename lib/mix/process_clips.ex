defmodule Mix.Tasks.ProcessClips do
  use Mix.Task

  @shortdoc "Process audio clips for transcription and embedding"

  def run(_args) do
    # Ensure your app and dependencies are started
    Mix.Task.run("app.start")

    # Start a supervisor for our audio transcription pipeline
    {:ok, _sup_pid} =
      DotaDeck.Ingestion.TranscriptionSupervisor.start_link(defn_options: [compiler: EXLA])

    # Call your pipeline function (replace with your actual module)
    DotaDeck.Ingestion.Processor.process_clips()
  end
end
