# Container mit Linux-Hausmitteln

### Was genau macht einen Container aus?
- Keine VM
  - Emulation des Prozessors
  - Betriebssystemkern
  - Geteilter RAM
  - ...
- Isolation "eines" Prozesses vom restlichen System
  - übriges System kann den Prozess sehen
  - Prozess aber nicht das übrige System
- Isolation auf Netzwerkebene
  - Freigabe einzelner Zugriff
  - komplette Freigabe ("host-net")
- Isolation des Dateisystems
  - chroot (kennt, wer mal sein System retten musste)
- limitierung von Ressourcen
  - cgroups für Hauptspeicher und CPU
    
### Das können wir alles mit Linux-Bordmitteln nachspielen
- Prozessisolation
  - linux namespaces
- Netzwerkisolation
  - linux namespaces
- Dateisystem 
  - s.o.
- Ressourcen
  - cgroups
- https://en.wikipedia.org/wiki/Linux_namespaces
- https://en.wikipedia.org/wiki/Cgroups

    
## Demo
- https://github.com/MichaelKreusel/bocker2.0
- In einer VM machen, auch wenn man eigentlich nicht wirklich nichts kaputt machen kann
