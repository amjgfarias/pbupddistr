#INCLUDE "TOTVS.CH"
#INCLUDE "FILEIO.CH"

/*/{Protheus.doc} xnuremake
   Rotina para ajustar falhas nos menus antes da migracao do dicionario para o banco.
   @type function
   @author Alessandro de Farias - amjgfarias@gmail.com
   @since 10/04/2021
/*/

User Function xnuremake
Local nI, nJ
Local cOrigem    := "d:\tcloud\" // "c:\r27\protheus_data\"
Local dDestino   := "d:\tcloud\novos_menus\" // "c:\r27\protheus_data\novos_menus"
Local Duplicados := "d:\tcloud\duplicados\" // "c:\r27\protheus_data\novos_menus"
// Local aPastas := {"menu-teste"} // {"menus","systemxnu"}
Local aPastas    := {"menus","systemxnu"}
Local aDir       := {}
FWMakeDir(dDestino,.F.)
FWMakeDir(Duplicados,.F.)
For nI:=1 To Len(aPastas)
	aDir := Directory( cOrigem+aPastas[nI]+"\*.xnu" )
	For nJ:=1 To Len(aDir)
		// ConOut( cOrigem+aPastas[nI]+"\"+aDir[nJ][01] + " -> " + lower(dDestino+"\"+aPastas[nI]+aDir[nJ][01]) )
		remake( lower(cOrigem+aPastas[nI]+"\"+aDir[nJ][01]), lower(dDestino+aPastas[nI]+"\"+aDir[nJ][01]), lower(dDestino + aPastas[nI]), lower(aDir[nJ][01]), lower(Duplicados + aPastas[nI]) )
	Next nJ
Next nI
Return


Static Function remake( cMenu, cNewNemnu, NewFolder, NewFile, Duplicados )
Local cLine   := Access := cItemId := ''
Local aLinhas := {}
Local nI      := 1
Local nItemID := 0
Local cTab  := Chr(9)
Local lvez1, lvez2, lvez3, lvez4
Local aItemId := {}
Local lIDDuplicado := .F.
Local cPBTimeI := Time()
FWMakeDir(NewFolder)
FWMakeDir(Duplicados)
FT_FUSE( cMenu )
FT_FGOTOP()
Do While ! FT_FEOF()
	cLine := Lower(NoAcento(FT_FREADLN()))
	If Lower('<itemid>') $ cline
		nItemID += 1
	Endif
	If nItemID >= 4
		Exit
	Endif
	FT_FSKIP()
Enddo
FT_FGOTOP()
nI := 0
Do While ! FT_FEOF()
	nI++
	cItemId := Substr( cLine, At('>',cLine)+1 )
	cItemId := Substr( cItemId, 1, At('<',cItemId)-1)
	If !Empty(cItemId)
		If aScan(aItemId,cItemId) == 0
			aAdd(aItemId,cItemId)
		Else
			If Len(aItemId) <> 0
				lIDDuplicado := .T.
			Endif
		Endif
	Endif
	FT_FSKIP()
Enddo
FT_FUSE()
FT_FUSE( cMenu )
FT_FGOTOP()
lvez1 := .T.
lvez2 := .T.
lvez3 := .T.
lvez4 := .T.
Do While ! FT_FEOF()
	cLine := FT_FREADLN()
	If Lower('<Access>') $ Lower( cLine ) .And. Lower('</Access>') $ Lower( cLine )
		Access := Substr( cLine, At('>',cLine)+1 )
		Access := Substr( Access, 1, At('<',Access)-1)
		Access := padr(lower(Left(Access,10)),10)
		cLine  := '     '+'<Access>'+Access+'</Access>'
	Endif
	If Lower('<Module>') $ Lower( cLine ) .And. Lower('</Module>') $ Lower( cLine )
		Module := Substr( cLine, At('>',cLine)+1 )
		Module := Substr( Module, 1, At('<',Module)-1)
		If Empty(Module) .Or. Module == "0"
			Module := '06'
		Endif
		If "USERMENU" $ Upper(Module)
			Module := 'SIGAFIN'
		Endif
		cLine  := '    '+'<Module>'+Module+'</Module>'
	Endif
	If Lower('<Version>') $ Lower( cLine ) .And. Lower('</Version>') $ Lower( cLine )
		Version := Substr( cLine, At('>',cLine)+1 )
		Version := Substr( Version, 1, At('<',Version)-1)
		If Empty(Version)
			Version := '10.1'
		Endif
		cLine  := ' '+'<Version>'+Version+'</Version>'
	Endif
	If Lower('<Type>') $ Lower( cLine ) .And. Lower('</Type>') $ Lower( cLine )
		cType := Substr( cLine, At('>',cLine)+1 )
		cType := Substr( cType, 1, At('<',cType)-1)
		If Empty(cType) .Or. cType == "0"
			cType := '03'
		Endif
		cLine  := '    '+'<Type>'+cType+'</Type>'
	Endif
	If !Empty(Alltrim(cLine))
		aAdd(aLinhas,cLine)
	Endif
	If lvez1 .And. 'title lang' $ Lower(NoAcento(cLine)) .And. 'updates' $ Lower(NoAcento(cLine)) .And. nItemID == 0
		aAdd(aLinhas,cTab+cTab+'<ItemID>A060000001</ItemID>')
		lvez1 := .F.
	Endif
	If lvez2 .And. 'title lang' $ Lower(NoAcento(cLine)) .And. 'searches' $ Lower(NoAcento(cLine)) .And. nItemID == 0
		aAdd(aLinhas,cTab+cTab+'<ItemID>A060000002</ItemID>')
		lvez2 := .F.
	Endif
	If lvez3 .And. 'title lang' $ Lower(NoAcento(cLine)) .And. 'reports' $ Lower(NoAcento(cLine)) .And. nItemID == 0
		aAdd(aLinhas,cTab+cTab+'<ItemID>A060000003</ItemID>')
		lvez3 := .F.
	Endif
	If lvez4 .And. 'title lang' $ Lower(NoAcento(cLine)) .And. 'miscellaneous' $ Lower(NoAcento(cLine)) .And. nItemID == 0
		aAdd(aLinhas,cTab+cTab+'<ItemID>A060000004</ItemID>')
		lvez4 := .F.
	Endif
	FT_FSKIP()
Enddo
FT_FUSE()
For nI:=1 To Len(aLinhas)
	If nI == 1
		fErase(cNewNemnu)
	Endif
	grv2txt( cNewNemnu, aLinhas[nI] )
Next nI
ConOut()
If __CopyFile( cNewNemnu, NewFolder + "\" + NewFile )
	ConOut( cNewNemnu + " -> " + NewFolder + "\" + NewFile + ' Duracao: ' + ElapTime( cPBTimeI, Time() ) )
Endif
If lIDDuplicado
	If __CopyFile( NewFolder + "\" + NewFile, Duplicados + "\" + NewFile )
		ConOut( 'Menu com Id duplicado '+ cNewNemnu + " -> " + Duplicados + "\" + NewFile )
		fErase(cNewNemnu)
		fErase(NewFolder + "\" + NewFile)
	Endif
Endif
Return


Static Function grv2txt( cArquivo, cTexto )
Local nHdl := 0
If !File(cArquivo)
	nHdl := FCreate(cArquivo)
Else
	nHdl := FOpen(cArquivo, FO_READWRITE)
Endif
FSeek(nHdl,0,FS_END)
cTexto += Chr(13)+Chr(10)
FWrite(nHdl, cTexto, Len(cTexto))
FClose(nHdl)
Return
