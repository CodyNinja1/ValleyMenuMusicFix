// Some variables to keep track of
namespace Current
{
    string MenuName = "";
    bool EditorAvailable = false;
}

// Some variables to keep track of
namespace Previous
{
    string MenuName = "";
    bool EditorAvailable = false;
}

// Constants
namespace C
{
    const array<string> UnallowedMenuNames = {
        "FrameManiaPlanetMain",
        "FrameDialog",
        "FrameAskYesNo"
    };
}

// Tracks if the music was patched or not by the plugin
bool HasPatchedMusic = false;

// Gets the currently active music source
CAudioSource@ GetMusicAudioSource(CGameCtnApp@ App)
{
    MwFastBuffer<CAudioSource@> AudioSources = App.AudioPort.Sources;
    for (uint SourceIdx = AudioSources.Length - 1; SourceIdx < AudioSources.Length; SourceIdx--)
    {
        CAudioSource@ Source = AudioSources[SourceIdx];
        // I think balance group is related to some sound dampening?
        // (e.g. when you crash your car, the music gets quiet but the crash sound gets louder)
        if (Source.BalanceGroup == CAudioSource::EAudioBalanceGroup::Music)
        {
            return Source;
        }
    }
    return null;
}

void Main()
{
    CTrackMania@ App = cast<CTrackMania>(GetApp());
    while (true)
    {
        // Update the current variables
        Current::EditorAvailable = App.Editor !is null;

        // If no menus are found (we are in editor probably)
        if (App.ActiveMenus.Length == 0) 
        {
            // There is no music to patch in editor, so we haven't patched it yet
            HasPatchedMusic = false;
            yield();
            continue;
        }

        // Update the current variables
        Current::MenuName = App.ActiveMenus[0].CurrentFrame.IdName;
        
        // If we are in a non-titlepack menu, then we are not in the titlepack and there is no music to patch
        if (C::UnallowedMenuNames.Find(Current::MenuName) >= 0) HasPatchedMusic = false;

        CAudioSource@ MusicSrc = GetMusicAudioSource(App);
        // If there is music playing...
        if (MusicSrc !is null)
        {
            // ...make sure that it is the valley main menu theme by the filename
            // (prone to error (because some titlepacks just replace it without changing filename), but eh)
            CSystemFidFile@ MusicFid = GetFidFromNod(MusicSrc.PlugSound.PlugFile);
            if (MusicFid !is null and MusicFid.ShortFileName == "ValleyMenu")
            {
                // If it is the valley menu theme, then check if we patched the music already
                if (!HasPatchedMusic)
                {
                    // If we haven't, then we can see if...
                    if (
                        // ...we transitioned into the titlepack menus or not
                        (C::UnallowedMenuNames.Find(Current::MenuName) < 0 and Current::MenuName != Previous::MenuName)
                        or
                        // ...or if we have exited the editor
                        !Current::EditorAvailable
                    )
                    {
                        // Stopping and starting the music makes it start from zero.
                        // It avoids glitching and stuttering over setting the play cursor to zero
                        MusicSrc.Stop();
                        yield();
                        MusicSrc.Play();
                        yield();

                        // We're done patching the music
                        HasPatchedMusic = true;
                    }
                }
            }
        }

        // Update tracked variables
        Previous::EditorAvailable = Current::EditorAvailable;
        Previous::MenuName = Current::MenuName;
        
        yield();
    }
}

void Render()
{
    UI::Begin("VMMF");

    UI::Text("Current.MenuName: " + tostring(Current::MenuName));
    UI::Text("Current.EditorAvailable: " + tostring(Current::EditorAvailable));

    UI::Text("Previous.MenuName: " + tostring(Previous::MenuName));
    UI::Text("Previous.EditorAvailable: " + tostring(Previous::EditorAvailable));

    UI::Text("HasPatched: " + tostring(HasPatchedMusic));

    UI::End();
}
