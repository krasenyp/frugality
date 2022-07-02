defmodule Frugal.Core.Condition do
  alias Frugal.Core.EntityTagSet
  alias Frugal.Core.Metadata

  @type t ::
          {:if_match | :if_none_match, EntityTagSet.t()}
          | {:if_unmodified_since | :if_modified_since, DateTime.t()}

  # Generate short-hand functions for creating conditions
  for c <- [:if_match, :if_none_match, :if_unmodified_since, :if_modified_since] do
    @spec unquote(c)(any()) :: t()
    def unquote(c)(value), do: {unquote(c), value}
  end

  @spec evaluate(t(), Metadata.t()) :: {atom(), boolean()}
  def evaluate({:if_match = c, _}, %Metadata{entity_tag: nil}), do: {c, false}
  def evaluate({:if_match = c, :any}, _), do: {c, true}

  def evaluate({:if_match = c, tags}, %Metadata{entity_tag: tag}),
    do: {c, EntityTagSet.matches_weak?(tags, tag)}

  def evaluate({:if_none_match = c, _}, %Metadata{entity_tag: nil}), do: {c, true}
  def evaluate({:if_none_match = c, :any}, _), do: {c, false}

  def evaluate({:if_none_match = c, tags}, %Metadata{entity_tag: tag}),
    do: {c, !EntityTagSet.matches_weak?(tags, tag)}

  def evaluate({:if_unmodified_since = c, _}, %Metadata{last_modified: nil}), do: {c, false}

  def evaluate({:if_unmodified_since = c, iums}, %Metadata{last_modified: lm}),
    do: {c, DateTime.compare(lm, iums) in [:lt, :eq]}

  def evaluate({:if_modified_since = c, _}, %Metadata{last_modified: nil}), do: {c, false}

  def evaluate({:if_modified_since = c, ims}, %Metadata{last_modified: lm}),
    do: {c, DateTime.compare(lm, ims) == :gt}
end
