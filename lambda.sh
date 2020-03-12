####!/usr/bin/env bash

# Anonymous functions in BASH
## Code

    function runner { 
       echo "Setting animal to: $1"
       someAnimal=$1 # Ensure that function is executing *NOW*
       source "$2"
    }
    
    someAnimal="Cow"
    runner "Monkey" <( cat <<'EOT'
      echo "  The value of someAnimal is '$someAnimal'."
    EOT
    )
    
    exit 0

## Results
 
    Setting animal to: Monkey
      The value of someAnimal is 'Monkey'.

###### This has been a literate BASH file (almost)
