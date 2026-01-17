package main

import (
	"bufio"
	"fmt"
	"io"
	"net/http"
	"os"
	"path/filepath"
	"strings"
)

var urlTemplates = []string{
	"https://shared.fastly.steamstatic.com/community_assets/images/apps/%s/%s",
	"https://cdn.cloudflare.steamstatic.com/steamcommunity/public/images/apps/%s/%s",
}

func main() {
	if len(os.Args) < 2 {
		fmt.Println("fix-steam-blank-icon path1 [path2 ...]")
		fmt.Println("args: path1 path2 ... - Paths to steam game shortcut files")
		os.Exit(1)
	}

	for _, path := range os.Args[1:] {
		if err := fixIcon(path); err != nil {
			fmt.Printf("Error processing %s: %v\n", path, err)
		}
	}

	fmt.Println("All done.")
}

func fixIcon(filePath string) error {
	fmt.Printf("Processing: %s\n", filePath)

	// Parse the shortcut file
	gameID, iconPath, err := parseShortcutFile(filePath)
	if err != nil {
		return err
	}

	// Open the icon outFile to check if it exists and is non-empty
	outFile, err := os.OpenFile(iconPath, os.O_WRONLY|os.O_CREATE|os.O_EXCL, 0644)
	if err != nil {
		if os.IsExist(err) {
			fmt.Printf("Icon file already exists, skipping: %s\n", iconPath)
			return nil
		}
		return fmt.Errorf("failed to open icon file: %w", err)
	}
	defer func() {
		outFile.Close()
		if err != nil {
			os.Remove(iconPath)
		}
	}()

	// Extract the icon file name
	iconName := filepath.Base(iconPath)

	// Try downloading the icon from multiple hosts
	for _, template := range urlTemplates {
		url := fmt.Sprintf(template, gameID, iconName)
		fmt.Printf("Attempting to download icon from: %s\n", url)
		// Download the icon
		resp, err := http.Get(url)
		if err != nil {
			fmt.Printf("Failed to download from %s: %v\n", url, err)
			continue
		}
		defer resp.Body.Close()
		if resp.StatusCode != http.StatusOK {
			fmt.Printf("Failed to download from %s: HTTP %d\n", url, resp.StatusCode)
			continue
		}
		// Save the icon file
		if _, err := io.Copy(outFile, resp.Body); err != nil {
			fmt.Printf("Failed to save icon from %s: %v\n", url, err)
			continue
		}
		return nil
	}
	return fmt.Errorf("failed to download icon for game ID %s", gameID)
}

// parseShortcutFile reads a shortcut file and extracts the URL and IconFile fields.
func parseShortcutFile(filePath string) (string, string, error) {
	file, err := os.Open(filePath)
	if err != nil {
		return "", "", fmt.Errorf("failed to open file: %w", err)
	}
	defer file.Close()

	var url, iconFile string
	scanner := bufio.NewScanner(file)
	for scanner.Scan() {
		line := strings.TrimSpace(scanner.Text())
		if strings.HasPrefix(line, "URL=") {
			url = strings.TrimPrefix(line, "URL=")
		} else if strings.HasPrefix(line, "IconFile=") {
			iconFile = strings.TrimPrefix(line, "IconFile=")
		}
	}
	if err := scanner.Err(); err != nil {
		return "", "", fmt.Errorf("failed to read file: %w", err)
	}

	if url == "" || iconFile == "" {
		return "", "", fmt.Errorf("missing URL or IconFile in shortcut")
	}

	gameID, err := extractGameID(url)
	if err != nil {
		return "", "", err
	}

	return gameID, iconFile, nil
}

// extractGameID extracts the game ID from a steam URL.
func extractGameID(url string) (string, error) {
	const steamPrefix = "steam://rungameid/"
	gameID := strings.TrimPrefix(url, steamPrefix)
	if !strings.HasPrefix(url, steamPrefix) || gameID == "" {
		return "", fmt.Errorf("invalid URL: %s", url)
	}
	return gameID, nil
}
