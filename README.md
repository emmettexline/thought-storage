This is a simple method for "Thought Storage" integrated into NeoVim

I made this as I was tired of thinking of ideas that I might want to implement in the future and just forgetting. This project acts as a library for your random thoughts organized and nammed automatically using Ollama's lightweight Llama 3.2 (about 2G disk space). I have found that Llama 3.2 effectively categorizes and summarizes even abstract ideas in the form of code or just words.


Usage:

To save a thought, open or create any file and execute :ST ("save thought")

To view the thought storage simply execute :B ("browse")

Inside the storage menu press enter on any thought to view it's contents
you can delete any thought by pressing d and confirming yes or no prompt, you can also edit any thought how you would for any file in Neovim


Installation:

1. Download and extract the zip file "thought-storage.zip"

2. Make sure Ollama is installed and running:

install ollama:

    ```curl -fsSL https://ollama.com/install.sh | sh```


start ollama backend:

Option 1:
    ```ollama serve```

Use of option 1 requires keeping the terminal running while ollama is running

Option 2:

    ```sudo systemctl start ollama```

This will start ollama in the background so you don't have to keep a terminal window open

install llama 3.2:

in the terminal:
    
    ```ollama pull llama3.2```

wait for llama3.2 to install


3. install Neovim plugin:

    make sure install.sh is executable (chmod +x ./install.sh)
    then run install.sh

4. Thats it you are done. Follow the usage section to use the plugin.
