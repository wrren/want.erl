defmodule Want.TestShape do
  use Want.Shape

  shape do
    field :int,   :integer,   default: 5
    field :str,   :string,    from: "StringField", default: "default"
  end
end
