defmodule DotaDeck.Ingestion.TranscriptionSupervisor do
  use Supervisor

  alias DotaDeck.MLModels.SpeechTranscription

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def init(opts) do
    children = [
      {Nx.Serving,
       serving: SpeechTranscription.serving(defn_options: opts[:defn_options]),
       name: SpeechTranscription,
       batch_size: 3,
       batch_timeout: 100}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
