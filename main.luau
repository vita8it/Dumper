local Dumper = {}
Dumper.__index = Dumper

function Dumper.define(Options)
    local self = setmetatable({}, Dumper)

    local HttpService = game:GetService("HttpService")

    self.Owner = "vita8it"
    self.Repository = "Dumper"

    self.Output = `DUMPER-{HttpService:GenerateGUID(false)}`

    self.Classes = self:Import("Utils/Classes")()

    self.DumpTables = {
        game:GetService('Players').LocalPlayer,
        game:GetService("ReplicatedStorage"),
        game:GetService("ReplicatedFirst"),
        game:GetService("SoundService"),
        game:GetService("Workspace"),
        game:GetService("Lighting"),
        game:GetService("Teams"),
    }

    self.Struction = {
        Explorer = "",
        Agent = "",
        Scripts = {},
        Sources = {},
    }

    self.ScriptNames = {}
    self.PendingScripts = 0
    self.TotalScripts = 0
    self.CompletedScripts = 0

    return self
end

function Dumper:GetUrl(Path)
    return `https://raw.githubusercontent.com/{self.Owner}/{self.Repository}/main/{Path}`
end

function Dumper:Import(Path)
    local Success, Result = pcall(function()
        return game:HttpGet(self:GetUrl(`{Path}.luau`))
    end)

    if not Success then
        warn(`[DUMPER] Import failed: {Path}`)
        warn(Result)

        return function()
            return {}
        end
    end

    local Loader, Error = loadstring(Result)

    if not Loader then
        warn(`[DUMPER] Compile failed: {Path}`)
        warn(Error)

        return function()
            return {}
        end
    end

    return Loader
end

function Dumper:ImportRaw(Path)
    local Success, Result = pcall(function()
        return game:HttpGet(self:GetUrl(Path))
    end)

    if not Success then
        warn(`[DUMPER] Import failed: {Path}`)
        warn(Result)

        return ""
    end

    return Result
end

function Dumper:GetProperties(Instance: Instance)
    return self.Classes[Instance.ClassName] or {}
end

function Dumper:GetPropertyValue(Instance: Instance, Property)
    local Success, Value = pcall(function()
        return Instance[Property]
    end)

    if not Success then
        return nil
    end

    return Value
end

function Dumper:SerializeValue(Value)
    local ValueType = typeof(Value)

    if ValueType == "Instance" then
        return {
            Type = "Instance",
            Value = Value:GetFullName(),
        }
    end

    if ValueType == "EnumItem" then
        return {
            Type = "EnumItem",
            Value = tostring(Value),
        }
    end

    if ValueType == "Color3" then
        return {
            Type = "Color3",
            Value = {
                R = Value.R,
                G = Value.G,
                B = Value.B,
            },
        }
    end

    if ValueType == "Vector2" then
        return {
            Type = "Vector2",
            Value = {
                X = Value.X,
                Y = Value.Y,
            },
        }
    end

    if ValueType == "Vector3" then
        return {
            Type = "Vector3",
            Value = {
                X = Value.X,
                Y = Value.Y,
                Z = Value.Z,
            },
        }
    end

    if ValueType == "UDim" then
        return {
            Type = "UDim",
            Value = {
                Scale = Value.Scale,
                Offset = Value.Offset,
            },
        }
    end

    if ValueType == "UDim2" then
        return {
            Type = "UDim2",
            Value = {
                X = {
                    Scale = Value.X.Scale,
                    Offset = Value.X.Offset,
                },
                Y = {
                    Scale = Value.Y.Scale,
                    Offset = Value.Y.Offset,
                },
            },
        }
    end

    if ValueType == "CFrame" then
        return {
            Type = "CFrame",
            Value = { Value:GetComponents() },
        }
    end

    if ValueType == "BrickColor" then
        return {
            Type = "BrickColor",
            Value = Value.Number,
        }
    end

    if ValueType == "NumberRange" then
        return {
            Type = "NumberRange",
            Value = {
                Min = Value.Min,
                Max = Value.Max,
            },
        }
    end

    if ValueType == "Rect" then
        return {
            Type = "Rect",
            Value = {
                Min = {
                    X = Value.Min.X,
                    Y = Value.Min.Y,
                },
                Max = {
                    X = Value.Max.X,
                    Y = Value.Max.Y,
                },
            },
        }
    end

    if ValueType == "PhysicalProperties" then
        return {
            Type = "PhysicalProperties",
            Value = {
                Density = Value.Density,
                Friction = Value.Friction,
                Elasticity = Value.Elasticity,
                FrictionWeight = Value.FrictionWeight,
                ElasticityWeight = Value.ElasticityWeight,
            },
        }
    end

    if ValueType == "Faces" then
        return {
            Type = "Faces",
            Value = tostring(Value),
        }
    end

    if ValueType == "table" then
        return Value
    end

    if ValueType == "function"
        or ValueType == "thread"
        or ValueType == "userdata" then
        return tostring(Value)
    end

    return Value
end

function Dumper:SerializeText(Value)
    local ValueType = typeof(Value)

    if ValueType == "string" then
        return string.format("%q", Value)
    end

    if ValueType == "Instance" then
        return Value:GetFullName()
    end

    if ValueType == "EnumItem" then
        return tostring(Value)
    end

    if ValueType == "Color3" then
        return `Color3({Value.R}, {Value.G}, {Value.B})`
    end

    if ValueType == "Vector2" then
        return `Vector2({Value.X}, {Value.Y})`
    end

    if ValueType == "Vector3" then
        return `Vector3({Value.X}, {Value.Y}, {Value.Z})`
    end

    if ValueType == "UDim" then
        return `UDim({Value.Scale}, {Value.Offset})`
    end

    if ValueType == "UDim2" then
        return `UDim2({Value.X.Scale}, {Value.X.Offset}, {Value.Y.Scale}, {Value.Y.Offset})`
    end

    if ValueType == "CFrame" then
        return `CFrame({table.concat({Value:GetComponents()}, ", ")})`
    end

    if ValueType == "BrickColor" then
        return tostring(Value)
    end

    if ValueType == "NumberRange" then
        return `NumberRange({Value.Min}, {Value.Max})`
    end

    if ValueType == "PhysicalProperties" then
        return `PhysicalProperties({Value.Density}, {Value.Friction}, {Value.Elasticity}, {Value.FrictionWeight}, {Value.ElasticityWeight})`
    end

    if ValueType == "Faces" then
        return tostring(Value)
    end

    if ValueType == "table" then
        local Success, Result = pcall(function()
            return game:GetService("HttpService"):JSONEncode(Value)
        end)

        if Success then
            return Result
        end

        return tostring(Value)
    end

    return tostring(Value)
end

function Dumper:GetAttributes(Instance: Instance)
    local Attributes = {}

    for Name, Value in Instance:GetAttributes() do
        Attributes[Name] = Value
    end

    return Attributes
end

function Dumper:GetPropertiesData(Instance: Instance)
    local Properties = {}
    local ClassProperties = self:GetProperties(Instance)

    for Property, Information in ClassProperties do
        local Value = self:GetPropertyValue(Instance, Property)

        if Value == nil then
            continue
        end

        Properties[Property] = {
            ValueType = Information.ValueType,
            Category = Information.Category,
            Serializable = Information.Serializable == true,
            ReadOnly = Information.ReadOnly == true,
            Value = self:SerializeValue(Value),
        }
    end

    return Properties
end

function Dumper:BuildTreeText(Instance: Instance, Prefix: string, IsLast: boolean, Output)
    local Branch = IsLast and "└── " or "├── "
    local ChildPrefix = IsLast and "    " or "│   "

    Output[#Output + 1] =
        `{Prefix}{Branch}{Instance.Name} [{Instance.ClassName}]`

    local Properties = self:GetProperties(Instance)
    local PropertyList = {}

    for Property, Information in Properties do
        local Value = self:GetPropertyValue(Instance, Property)

        if Value == nil then
            continue
        end

        PropertyList[#PropertyList + 1] = {
            Name = Property,
            Information = Information,
            Value = Value,
        }
    end

    table.sort(PropertyList, function(A, B)
        return A.Name < B.Name
    end)

    if #PropertyList > 0 then
        Output[#Output + 1] =
            `{Prefix}{ChildPrefix}Properties:`

        for Index, Property in PropertyList do
            local Value = self:SerializeText(Property.Value)
            local BranchType = Index == #PropertyList and "└── " or "├── "

            Output[#Output + 1] =
                `{Prefix}{ChildPrefix}    {BranchType}{Property.Name} = {Value}`
        end
    end

    local Attributes = Instance:GetAttributes()
    local AttributeNames = {}

    for Name in Attributes do
        AttributeNames[#AttributeNames + 1] = Name
    end

    table.sort(AttributeNames)

    if #AttributeNames > 0 then
        Output[#Output + 1] =
            `{Prefix}{ChildPrefix}Attributes:`

        for Index, Name in AttributeNames do
            local Value = self:SerializeText(Attributes[Name])
            local BranchType = Index == #AttributeNames and "└── " or "├── "

            Output[#Output + 1] =
                `{Prefix}{ChildPrefix}    {BranchType}{Name} = {Value}`
        end
    end

    local Children = Instance:GetChildren()

    for Index, Child in Children do
        local IsChildLast = Index == #Children

        self:BuildTreeText(
            Child,
            `{Prefix}{ChildPrefix}`,
            IsChildLast,
            Output
        )
    end
end

function Dumper:BuildExplorer()
    local Output = {}

    for Index, Root in self.DumpTables do
        local IsLast = Index == #self.DumpTables

        self:BuildTreeText(
            Root,
            "",
            IsLast,
            Output
        )
    end

    return table.concat(Output, "\n")
end

function Dumper:IsScript(Instance: Instance)
    if not Instance:IsA("LuaSourceContainer") then
        return false
    end

    if Instance:IsA("Script") then
        local Success, RunContext = pcall(function()
            return Instance.RunContext
        end)

        if Success and RunContext ~= "Client" then
            return false
        end
    end

    return true
end

function Dumper:GetScriptName(Instance: Instance)
    local Name = Instance.Name:gsub("[<>:\"/\\|%?%*]", "_")
    local Count = self.ScriptNames[Name] or 0

    Count += 1
    self.ScriptNames[Name] = Count

    if Count == 1 then
        return `{Name}.lua`
    end

    return `{Name}({Count}).lua`
end

function Dumper:Decompile(Instance: Instance)
    local Path = Instance:GetFullName()

    local Success, Source = pcall(function()
        return decompile(Instance)
    end)

    if not Success then
        warn(`[DUMPER] Decompile failed: {Path}`)
        warn(Source)

        return nil
    end

    if type(Source) ~= "string" then
        warn(`[DUMPER] Decompile failed: {Path}`)
        warn("Decompiler returned invalid source")

        return nil
    end

    print(`[DUMPER] Decompiled: {Path}`)

    return `-- Path : {Path}\n{Source}`
end

function Dumper:AddScript(Instance: Instance)
    local Name = self:GetScriptName(Instance)
    local Path = Instance:GetFullName()

    self.PendingScripts += 1
    self.TotalScripts += 1

    task.spawn(function()
        local Source = self:Decompile(Instance)

        if Source then
            self.Struction.Scripts[#self.Struction.Scripts + 1] = {
                Name = Name,
                Source = Source,
                Path = Path,
            }

            self.CompletedScripts += 1
        end

        self.PendingScripts -= 1
    end)
end

function Dumper:ScanScripts(Instance: Instance)
    if self:IsScript(Instance) then
        self:AddScript(Instance)
        return
    end

    for _, Child in Instance:GetChildren() do
        self:ScanScripts(Child)
    end
end

function Dumper:BuildScripts()
    self.Struction.Scripts = {}
    self.ScriptNames = {}
    self.PendingScripts = 0
    self.TotalScripts = 0
    self.CompletedScripts = 0

    for _, Root in self.DumpTables do
        self:ScanScripts(Root)
    end

    while self.PendingScripts > 0 do
        task.wait()
    end

    table.sort(self.Struction.Scripts, function(A, B)
        return A.Path < B.Path
    end)

    print(
        `[DUMPER] Decompiled {self.CompletedScripts}/{self.TotalScripts} scripts`
    )

    return self.Struction.Scripts
end

function Dumper:Build()
    self.Struction.Explorer = self:BuildExplorer()

    self:BuildScripts()

    self.Struction.Agent = self:ImportRaw("AGENT.md")

    return self.Struction
end

function Dumper:EnsureFolder(Path)
    if isfolder(Path) then
        return true
    end

    local Success, Error = pcall(function()
        makefolder(Path)
    end)

    if not Success and not isfolder(Path) then
        warn(`[DUMPER] Failed to create folder: {Path}`)
        warn(Error)

        return false
    end

    return true
end

function Dumper:WriteExplorer()
    local Path = `{self.Output}/Explorer.txt`

    local Success, Error = pcall(function()
        writefile(
            Path,
            self.Struction.Explorer
        )
    end)

    if not Success then
        warn(`[DUMPER] Failed to write Explorer.txt`)
        warn(Error)

        return false
    end

    print(`[DUMPER] Saved: {Path}`)

    return true
end

function Dumper:WriteAgent()
    local Path = `{self.Output}/AGENT.md`

    local Success, Error = pcall(function()
        writefile(
            Path,
            self.Struction.Agent or ""
        )
    end)

    if not Success then
        warn(`[DUMPER] Failed to write AGENT.md`)
        warn(Error)

        return false
    end

    print(`[DUMPER] Saved: {Path}`)

    return true
end

function Dumper:WriteScripts()
    local ScriptsPath = `{self.Output}/Scripts`

    if not self:EnsureFolder(ScriptsPath) then
        return false
    end

    for _, Script in self.Struction.Scripts do
        local Path = `{ScriptsPath}/{Script.Name}`

        local Success, Error = pcall(function()
            writefile(
                Path,
                Script.Source
            )
        end)

        if not Success then
            warn(`[DUMPER] Failed to write: {Script.Path}`)
            warn(Error)

            continue
        end

        print(`[DUMPER] Saved: {Path}`)
    end

    return true
end

function Dumper:WriteSources()
    local SourcesPath = `{self.Output}/Sources`

    if not self:EnsureFolder(SourcesPath) then
        return false
    end

    print(`[DUMPER] Created empty Sources folder: {SourcesPath}`)

    return true
end

function Dumper:Write()
    if not self:EnsureFolder(self.Output) then
        return
    end

    print(`[DUMPER] Starting dump: {self.Output}`)

    self:Build()

    self:WriteExplorer()
    self:WriteAgent()
    self:WriteScripts()
    self:WriteSources()

    print(`[DUMPER] Dump completed: {self.Output}`)

    return self.Struction
end

function Dumper:Dump()
    return self:Write()
end

return Dumper.define({
    "This file create by vita8it"
}):Dump()
