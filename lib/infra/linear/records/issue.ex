defmodule Infra.Linear.Records.Issue do
  @moduledoc """
  A Linear issue object.
  """

  use Infra.LinearObject

  alias Infra.Linear.Records.Comment
  alias Infra.Linear.Records.WorkflowState
  alias Infra.Linear.Records.User

  # assignee: User
  # attachments (linked issues?): [Issue]
  # boardOrder
  # children: [Issue]
  # cycle: Cycle TODO: PQ-4
  # dueDate: DateTime (although says timeless?)
  # history: IssueHistoryConnection TODO: PQ-5
  # identifier: human readable id string
  # inverseRelations: IssueRelationConnection TODO: PQ-6
  # labels: IssueLabelConnection TODO: PQ-7
  # parent: Issue
  # priorityLabel (maybe?): String
  # project: Project TODO: PQ-8
  # projectMilestones: ProjectMilestones TODO: PQ-9
  # relations: IssueRelationConnection
  # sortOrder: Float

  @type issue :: %__MODULE__{
          id: String.t(),
          identifier: String.t(),
          branchName: String.t(),
          comments: [Comment.t()],
          createdAt: DateTime.t(),
          creator: User.t(),
          description: String.t(),
          estimate: Float.t(),
          priority: Float.t(),
          state: WorkflowState.issue_status(),
          title: String.t(),
          url: String.t()
        }

  object do
    field :id, :string
    field :identifier, :string
    field :branchName, :string
    nodes(:comments, Comment)
    field :createdAt, :utc_datetime
    embed(:creator, User)
    field :description, :string
    field :estimate, :float
    field :priority, :float
    embed(:state, WorkflowState)
    field :title, :string
    field :url, :string
  end
end
