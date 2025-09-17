-- WindUI Demo Script (Cleaned & Fixed)

-- Load WindUI library
local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/FootageSUS/WindUI/main/library.lua"))()

-- Localization example
WindUI.Locale = {
    ["en"] = {
        welcome = "Welcome to WindUI!",
        clickme = "Click Me",
    },
    ["es"] = {
        welcome = "¡Bienvenido a WindUI!",
        clickme = "Haz clic aquí",
    }
}

-- Theme + transparency settings
WindUI.Theme = "Dark"
WindUI.Transparency = 0.15

-- Gradient Title Example
WindUI:Title({
    Text = "Twilight Zone GUI",
    Gradient = {
        Color = ColorSequence.new{
            ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 128)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 128, 255))
        }
    }
})

-- Popup Example
WindUI:Popup({
    Title = "Hello!",
    Description = WindUI:GetLocale("welcome"),
    Buttons = {
        {
            Name = WindUI:GetLocale("clickme"),
            Callback = function()
                print("Button clicked!")
            end
        }
    }
})

-- Example: Adding your own key system service
WindUI.Services.MyKeyService = {
    Name = "My Key System",
    Icon = "lock", -- can be lucide-react icon name, rbxassetid, or image link

    Args = { "ServiceId" }, -- must match with New function args

    New = function(ServiceId)

        local function validateKey(key)
            if not key or key == "" then
                return false, "Key is invalid!"
            end
            return true, "Key is valid!"
        end

        local function copyLink()
            setclipboard("https://your-key-service-link.com")
        end

        return {
            Verify = validateKey, -- IMPORTANT: key validator
            Copy = copyLink       -- OPTIONAL: copy link to clipboard
        }
    end
}

print("✅ WindUI Demo Script Loaded Successfully!")
