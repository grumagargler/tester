#if ( server or externalconnection ) then

function Pick(Tags) export

	BeginTransaction();
	lockTags();
	tag = tagsToKey(Tags);
	CommitTransaction();
	return tag;

endfunction

procedure lockTags()

	lock = new DataLock();
	item = lock.Add("Catalog.TagKeys");
	item.Mode = DataLockMode.Exclusive;
	lock.Lock();

endprocedure

function tagsToKey(Tags)

	values = update(Tags);
	ref = findKey(Tags);
	if (ref <> undefined) then
		return ref;
	endif;
	if (values.Count() = 0) then
		return undefined;
	endif;
	obj = Catalogs.TagKeys.CreateItem();
	obj.Tags.Load(values);
	obj.SetDescription();
	obj.Write();
	return obj.Ref;

endfunction

function update(Tags)

	list = existedTags(Tags);
	for each tag in Tags do
		if (list.Find(tag, "Name") = undefined) then
			row = list.Add ();
			row.Tag = newTag(tag);
			row.Name = tag;
		endif;
	enddo;
	return list;

endfunction

function existedTags(Tags)
	
	s = "
	|select Tags.Ref as Tag, Tags.Description as Name
	|from Catalog.Tags as Tags
	|where Tags.Description in ( &Tags )
	|and not Tags.DeletionMark
	|";
	q = new Query(s);
	q.SetParameter("Tags", Tags);
	return q.Execute().Unload();
	
endfunction

function newTag(Name)
	
	obj = Catalogs.Tags.CreateItem();
	obj.Description = Name;
	obj.Write();
	return obj.Ref;
	
endfunction

function findKey(Tags)

	s = "
	|select top 1 Keys.Ref as Ref
	|from (
	|	select TagKeys.Ref as Ref, case when Tags.Tag is null then -1 else 1 end as Count
	|	from Catalog.TagKeys.Tags as TagKeys
	|		//
	|		// TagsCount
	|		//
	|		left join (
	|			select Tags.Ref as Tag
	|			from Catalog.Tags as Tags
	|			where Tags.Description in ( &Tags )
	|		) as Tags
	|		on Tags.Tag = TagKeys.Tag
	|	union all
	|	select TagKeys.Ref, -1
	|	from Catalog.TagKeys as TagKeys,
	|		 Catalog.Tags as Classifier
	|	where Classifier.Description in ( &Tags )
	|) as Keys
	|group by Keys.Ref
	|having sum ( Keys.Count ) = 0
	|";
	q = new Query(s);
	q.SetParameter("Tags", Tags);
	table = q.Execute().Unload();
	return ?(table.Count() = 0, undefined, table[0].Ref);

endfunction

#endif
