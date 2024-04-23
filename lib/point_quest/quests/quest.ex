defmodule PointQuest.Quests.Quest do
  @moduledoc """
  Object for holding the current voting context
  """

  @behaviour Projectionist.Projection

  use Ecto.Schema

  alias PointQuest.Quests
  alias PointQuest.Quests.Adventurer
  alias PointQuest.Quests.Party
  alias PointQuest.Quests.Attack
  alias PointQuest.Quests.Commands
  alias PointQuest.Quests.Event

  @primary_key {:id, :binary_id, autogenerate: true}
  embedded_schema do
    embeds_many :attacks, Attack
    embeds_one :party, Party
    field :round_active?, :boolean
    field :quest_objective, :string
  end

  def init() do
    {:ok,
     %__MODULE__{
       id: nil,
       party: nil,
       attacks: [],
       round_active?: false,
       quest_objective: ""
     }}
  end

  def project(%Event.QuestStarted{party_leaders_adventurer: nil} = event, quest) do
    party =
      %Party{}
      |> Party.changeset(%{
        party_leader: %{
          id: event.leader_id,
          quest_id: event.quest_id
        }
      })
      |> Ecto.Changeset.apply_action!(:insert)

    %__MODULE__{
      quest
      | id: event.quest_id,
        party: party
    }
  end

  def project(%Event.QuestStarted{} = event, quest) do
    party_leaders_adventurer_params =
      event.party_leaders_adventurer
      |> Ecto.embedded_dump(:json)
      |> Map.put(:quest_id, event.quest_id)
      |> Map.put(:id, event.leader_id)

    party =
      %Party{}
      |> Party.changeset(%{
        party_leader: %{
          id: event.leader_id,
          quest_id: event.quest_id,
          adventurer: party_leaders_adventurer_params
        }
      })
      |> Ecto.Changeset.apply_action!(:insert)

    %__MODULE__{
      quest
      | id: event.quest_id,
        party: party,
        round_active?: false
    }
  end

  def project(%Event.AdventurerJoinedParty{} = event, quest) do
    adventurer =
      %Quests.Adventurer{}
      |> Adventurer.create_changeset(%{
        id: event.id,
        name: event.name,
        class: event.class,
        quest_id: event.quest_id
      })
      |> Ecto.Changeset.apply_action!(:insert)

    party =
      %Party{
        quest.party
        | adventurers: [adventurer | quest.party.adventurers]
      }

    %__MODULE__{
      quest
      | party: party
    }
  end

  def project(%Event.AdventurerAttacked{} = command, %__MODULE__{attacks: attacks} = quest) do
    # adventurer could be updating their previous attack
    updated_attacks =
      [struct(Attack, Map.take(command, [:adventurer_id, :attack])) | attacks]
      |> Enum.uniq_by(fn %{adventurer_id: id} -> id end)

    %__MODULE__{
      quest
      | attacks: updated_attacks
    }
  end

  def project(%Event.RoundStarted{quest_objective: objective}, %__MODULE__{} = quest) do
    %__MODULE__{
      quest
      | round_active?: true,
        attacks: [],
        quest_objective: objective
    }
  end

  def project(%Event.RoundEnded{}, %__MODULE__{} = quest) do
    %__MODULE__{
      quest
      | round_active?: false,
        quest_objective: ""
    }
  end

  def handle(%Commands.StartQuest{party_leaders_adventurer: nil} = command, _quest) do
    event =
      command
      |> Ecto.embedded_dump(:json)
      |> Map.merge(%{leader_id: Nanoid.generate_non_secure()})
      |> Event.QuestStarted.new!()

    {:ok, event}
  end

  def handle(%Commands.StartQuest{} = command, _quest) do
    leader_id = Nanoid.generate_non_secure()

    event =
      command
      |> Ecto.embedded_dump(:json)
      |> Map.merge(%{leader_id: leader_id})
      |> update_in([:party_leaders_adventurer, :id], fn _ -> leader_id end)
      |> Event.QuestStarted.new!()

    {:ok, event}
  end

  def handle(%Commands.AddAdventurer{} = command, quest) do
    if Enum.any?(quest.party.adventurers, fn a -> a.name == command.name end) do
      {:error, :adventurer_already_present}
    else
      {:ok, Event.AdventurerJoinedParty.new!(Ecto.embedded_dump(command, :json))}
    end
  end

  def handle(%Commands.Attack{} = command, _quest) do
    {:ok, Event.AdventurerAttacked.new!(Ecto.embedded_dump(command, :json))}
  end

  def handle(%Commands.StartRound{} = command, quest) do
    if quest.round_active? do
      {:error, :round_already_active}
    else
      {:ok, Event.RoundStarted.new!(Ecto.embedded_dump(command, :json))}
    end
  end

  def handle(%Commands.StopRound{} = command, quest) do
    if quest.round_active? do
      {:ok, Event.RoundEnded.new!(Ecto.embedded_dump(command, :json))}
    else
      {:error, :round_not_active}
    end
  end
end
