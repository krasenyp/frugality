defmodule Frugal.Core.Conditions do
  alias Frugal.Core.Condition
  alias Frugal.Core.Metadata

  @type result :: :ok | :precondition_failed | :not_modified

  @type t :: %__MODULE__{
          method: String.t(),
          conditions: Enum.t()
        }

  defstruct [:method, conditions: []]

  @spec new(Enum.t()) :: t()
  def new(fields) do
    struct!(__MODULE__, fields)
  end

  @spec evaluate(t(), Metadata.t()) :: result()
  def evaluate(%__MODULE__{method: method, conditions: conditions}, %Metadata{} = metadata) do
    conditions
    |> Stream.map(&Condition.evaluate(&1, metadata))
    |> Enum.reduce_while(:ok, &determine_status(method, &1, &2))
  end

  defp determine_status(method, {:if_none_match, false}, _) when method in ["GET", "HEAD"],
    do: {:halt, :not_modified}

  defp determine_status(_, {:if_modified_since, false}, _),
    do: {:halt, :not_modified}

  defp determine_status(_, {_, false}, _), do: {:halt, :precondition_failed}

  defp determine_status(_, _, acc), do: {:cont, acc}
end
