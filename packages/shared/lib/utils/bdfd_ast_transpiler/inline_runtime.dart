part of '../bdfd_ast_transpiler.dart';

extension _BdfdAstTranspilationScopeInlineRuntime
    on _BdfdAstTranspilationScope {
  String? _stringifyInlineFunction(BdfdFunctionCallAst node) {
    // Runtime loop variable placeholders (e.g. $i → ((_loop.var.i))).
    // Also handle $jsonKey[]/$jsonValue[]/$jsonIndex[] whose empty brackets
    // produce a single empty argument rather than zero arguments.
    final hasEmptyBrackets =
        node.arguments.length == 1 && node.arguments.first.isEmpty;
    final isEffectivelyEmptyArgs = node.arguments.isEmpty || hasEmptyBrackets;

    if (_runtimeLoopVarNames != null &&
        _loopDepth > 0 &&
        isEffectivelyEmptyArgs) {
      final name = node.normalizedName;
      if (_runtimeLoopVarNames!.contains(name)) {
        return '((_loop.var.$name))';
      }
      if (name == 'i' || name == 'loopindex' || name == 'loopiteration') {
        return '((_loop.index))';
      }
      if (name == 'loopcount') {
        return '((_loop.count))';
      }
    }
    // C-style loop variables take precedence (e.g. $i, $j in a for loop).
    if (_loopDepth > 0 && isEffectivelyEmptyArgs) {
      final loopVar = _loopVariables[node.normalizedName];
      if (loopVar != null) return loopVar.toString();
    }
    // List iteration string variables (e.g. $item in $for[item;a;b;c]).
    if (_loopDepth > 0 && isEffectivelyEmptyArgs) {
      final stringVar = _loopStringVariables[node.normalizedName];
      if (stringVar != null) return stringVar;
    }
    switch (node.normalizedName) {
      case 'webhookcreate':
        final action = _buildWebhookCreateAction(node);
        _deferredInlineActions.add(action);
        return '((${action.key}))';
      case 'addemoji':
        final action = _buildAddEmojiAction(node);
        if (action != null) {
          _deferredInlineActions.add(action);
        }
        final returnEmojiRaw = _stringifyArgument(node, 2).trim().toLowerCase();
        final returnEmoji = returnEmojiRaw == 'yes' || returnEmojiRaw == 'true';
        if (returnEmoji && action != null) {
          return '((${action.key}.tag))';
        }
        return '';
      case 'createchannel':
        final action = _buildCreateChannelAction(node);
        if (action != null) {
          _deferredInlineActions.add(action);
          return '((${action.key}))';
        }
        return '';
      case 'newticket':
        final action = _buildNewTicketAction(node);
        _deferredInlineActions.add(action);
        return '((${action.key}))';
      case 'startthread':
        final action = _buildStartThreadAction(node);
        if (action != null) {
          _deferredInlineActions.add(action);
        }
        return _shouldReturnStartThreadId(node) ? '((thread.lastId))' : '';
      case 'editthread':
        final action = _buildEditThreadAction(node);
        if (action != null) {
          _deferredInlineActions.add(action);
        }
        return '';
      case 'threadaddmember':
        final action = _buildThreadMemberAction(node, add: true);
        if (action != null) {
          _deferredInlineActions.add(action);
        }
        return '';
      case 'threadremovemember':
        final action = _buildThreadMemberAction(node, add: false);
        if (action != null) {
          _deferredInlineActions.add(action);
        }
        return '';
      case 'checkuserperms':
      case 'checkusersperms':
      case 'hasperms':
        return _inlineCheckUserPerms(node);
      case 'message':
        return _inlineMessageArgument(node);
      case 'authorofmessage':
        final messageId = _stringifyArgument(node, 0).trim();
        return messageId.isEmpty
            ? '((target.message.author.id|author.id))'
            : '((message[$messageId].authorId))';
      case 'args':
        return _inlineArgsArgument(node);
      case 'i':
      case 'loopindex':
      case 'loopiteration':
        return _loopDepth > 0 ? _loopIterationIndex.toString() : '0';
      case 'loopcount':
        return _loopDepth > 0 ? (_loopIterationIndex + 1).toString() : '0';
      case 'mentionedchannels':
        return _inlineMentionedChannels(node);
      // ── Select menu interaction results ──
      case 'getmentionableselectuserid':
        final pos = _stringifyArgument(node, 0).trim();
        return '((interaction.mentionableSelect.userId${pos.isNotEmpty ? '[$pos]' : ''}))';
      case 'getmentionableselectuserids':
        final sep = _stringifyArgument(node, 0).trim();
        return '((interaction.mentionableSelect.userIds${sep.isNotEmpty ? '[$sep]' : ''}))';
      case 'getuserselectuserid':
        final pos = _stringifyArgument(node, 0).trim();
        return '((interaction.userSelect.userId${pos.isNotEmpty ? '[$pos]' : ''}))';
      case 'getuserselectuserids':
        final sep = _stringifyArgument(node, 0).trim();
        return '((interaction.userSelect.userIds${sep.isNotEmpty ? '[$sep]' : ''}))';
      case 'getroleselectroleid':
        final pos = _stringifyArgument(node, 0).trim();
        return '((interaction.roleSelect.roleId${pos.isNotEmpty ? '[$pos]' : ''}))';
      case 'getroleselectroleids':
        final sep = _stringifyArgument(node, 0).trim();
        return '((interaction.roleSelect.roleIds${sep.isNotEmpty ? '[$sep]' : ''}))';
      case 'getchannelselectchannelid':
        final pos = _stringifyArgument(node, 0).trim();
        return '((interaction.channelSelect.channelId${pos.isNotEmpty ? '[$pos]' : ''}))';
      case 'getchannelselectchannelids':
        final sep = _stringifyArgument(node, 0).trim();
        final limit = _stringifyArgument(node, 1).trim();
        return '((interaction.channelSelect.channelIds${sep.isNotEmpty ? '[$sep${limit.isNotEmpty ? ';$limit' : ''}]' : ''}))';
      case 'getstringselectvalue':
        final pos = _stringifyArgument(node, 0).trim();
        return '((interaction.stringSelect.value${pos.isNotEmpty ? '[$pos]' : ''}))';
      case 'getstringselectvalues':
        final sep = _stringifyArgument(node, 0).trim();
        final limit = _stringifyArgument(node, 1).trim();
        return '((interaction.stringSelect.values${sep.isNotEmpty ? '[$sep${limit.isNotEmpty ? ';$limit' : ''}]' : ''}))';
      case 'user':
        if (node.arguments.isNotEmpty) {
          final userId = _stringifyArgument(node, 0).trim();
          if (userId.isNotEmpty) {
            return '<@$userId>';
          }
        }
        return _inlineRuntimeVariables['user'];
      case 'username':
        if (node.arguments.isNotEmpty) {
          final userId = _stringifyArgument(node, 0).trim();
          if (userId.isNotEmpty) {
            return '((user[$userId].username))';
          }
        }
        return _inlineRuntimeVariables['username'];
      case 'nickname':
      case 'membernick':
        if (node.arguments.isNotEmpty) {
          final userId = _stringifyArgument(node, 0).trim();
          if (userId.isNotEmpty) {
            return '((member[$userId].nick|member[$userId].displayName|user[$userId].displayName|user[$userId].username))';
          }
        }
        return _inlineRuntimeVariables[node.normalizedName];
      case 'displayname':
        if (node.arguments.isNotEmpty) {
          final userId = _stringifyArgument(node, 0).trim();
          if (userId.isNotEmpty) {
            return '((member[$userId].displayName|user[$userId].displayName))';
          }
        }
        return _inlineRuntimeVariables['displayname'];
      case 'isadmin':
        if (node.arguments.isNotEmpty) {
          final userId = _stringifyArgument(node, 0).trim();
          if (userId.isNotEmpty) {
            return '((member[$userId].isAdmin))';
          }
        }
        return _inlineRuntimeVariables['isadmin'];
      case 'isbooster':
        if (node.arguments.isNotEmpty) {
          final userId = _stringifyArgument(node, 0).trim();
          if (userId.isNotEmpty) {
            return '((member[$userId].isBooster))';
          }
        }
        return _inlineRuntimeVariables['isbooster'];
      case 'highestrole':
        if (node.arguments.isNotEmpty) {
          final userId = _stringifyArgument(node, 0).trim();
          if (userId.isNotEmpty) {
            return '((member[$userId].highestRole))';
          }
        }
        return '((roleBoundary[((guild.id));highest]))';
      case 'lowestrole':
        if (node.arguments.isNotEmpty) {
          final userId = _stringifyArgument(node, 0).trim();
          if (userId.isNotEmpty) {
            return '((member[$userId].lowestRole))';
          }
        }
        return '((roleBoundary[((guild.id));lowest]))';
      case 'highestrolewithperms':
        final highestPermissions = [
          for (var i = 0; i < node.arguments.length; i++)
            _stringifyArgument(node, i).trim(),
        ].where((value) => value.isNotEmpty).join(';');
        if (highestPermissions.isEmpty) return '';
        return '((roleBoundaryWithPerms[((guild.id));highest;$highestPermissions]))';
      case 'lowestrolewithperms':
        final lowestPermissions = [
          for (var i = 0; i < node.arguments.length; i++)
            _stringifyArgument(node, i).trim(),
        ].where((value) => value.isNotEmpty).join(';');
        if (lowestPermissions.isEmpty) return '';
        return '((roleBoundaryWithPerms[((guild.id));lowest;$lowestPermissions]))';
      case 'userexists':
        if (node.arguments.isNotEmpty) {
          final userId = _stringifyArgument(node, 0).trim();
          if (userId.isNotEmpty) {
            return '((user[$userId].exists))';
          }
        }
        return _inlineRuntimeVariables['userexists'];
      case 'finduser':
        final query = _stringifyArgument(node, 0).trim();
        final fallback = _stringifyArgument(node, 1).trim().toLowerCase();
        return '((userFind[$query;${fallback == 'no' ? 'no' : 'yes'}].id))';
      case 'channelexists':
        if (node.arguments.isNotEmpty) {
          final channelId = _stringifyArgument(node, 0).trim();
          if (channelId.isNotEmpty) {
            return '((channel[$channelId].exists))';
          }
        }
        return _inlineRuntimeVariables[node.normalizedName] ?? 'false';
      case 'serverchannelexists':
        if (node.arguments.isNotEmpty) {
          final name = _stringifyArgument(node, 0).trim();
          final guildId = _stringifyArgument(node, 1).trim();
          if (name.isNotEmpty) {
            return '((channelSearch[$guildId;$name].exists))';
          }
        }
        return 'false';
      case 'guildexists':
      case 'serverexists':
        if (node.arguments.isNotEmpty) {
          final guildId = _stringifyArgument(node, 0).trim();
          if (guildId.isNotEmpty) {
            return '((guild[$guildId].exists))';
          }
        }
        return _inlineRuntimeVariables[node.normalizedName] ?? 'false';
      case 'memberscount':
      case 'allmemberscount':
        if (node.arguments.isNotEmpty) {
          final presence = _stringifyArgument(node, 0).trim().toLowerCase();
          if (presence.isNotEmpty) {
            return '((guild.${presence}Members))';
          }
        }
        return _inlineRuntimeVariables[node.normalizedName];
      case 'servernames':
        if (node.arguments.isNotEmpty) {
          final amount = _stringifyArgument(node, 0).trim();
          final separator = node.arguments.length > 1
              ? _stringifyArgument(node, 1)
              : ', ';
          return '((servernames[$amount;$separator]))';
        }
        return _inlineRuntimeVariables['servernames'];
      // Parametric channel/guild lookups
      case 'channelid':
      case 'channelidfromname':
        if (node.arguments.isNotEmpty) {
          final channelName = _stringifyArgument(node, 0).trim();
          if (channelName.isNotEmpty) {
            return '((channel[$channelName].id))';
          }
        }
        return _inlineRuntimeVariables['channelid'];
      case 'findchannel':
        if (node.arguments.isNotEmpty) {
          final query = _stringifyArgument(node, 0).trim();
          if (query.isNotEmpty) return '((channelFind[$query].id))';
        }
        return '';
      case 'getslowmode':
        // An explicit channel must not fall back to the triggering channel.
        if (node.arguments.isNotEmpty) {
          final channelId = _stringifyArgument(node, 0).trim();
          if (channelId.isNotEmpty) {
            return '((channel[$channelId].rateLimitPerUser))';
          }
        }
        return _inlineRuntimeVariables['getslowmode'];
      case 'channelname':
      case 'channeltype':
      case 'channeltopic':
      case 'channelposition':
      case 'parentid':
      case 'categoryid':
      case 'channelcategoryid':
      case 'channelnsfw':
      case 'isnsfw':
      case 'lastmessageid':
      case 'lastpintimestamp':
        final channelId = _stringifyArgument(node, 0).trim();
        if (channelId.isNotEmpty) {
          final field = switch (node.normalizedName) {
            'channelname' => 'name',
            'channeltype' => 'type',
            'channeltopic' => 'topic',
            'channelposition' => 'position',
            'parentid' || 'categoryid' || 'channelcategoryid' => 'parentId',
            'channelnsfw' || 'isnsfw' => 'nsfw',
            'lastmessageid' => 'lastMessageId',
            'lastpintimestamp' => 'lastPinTimestamp',
            _ => 'name',
          };
          return '((channel[$channelId].$field))';
        }
        return _inlineRuntimeVariables[node.normalizedName];
      case 'channelnames':
        final separator = node.arguments.isNotEmpty
            ? _stringifyArgument(node, 0)
            : '__default__';
        final guildId = node.arguments.length > 1
            ? _stringifyArgument(node, 1).trim()
            : '';
        return '((channelList[all;$separator;$guildId].names))';
      case 'channelcount':
        final categoryId = _stringifyArgument(node, 0).trim();
        if (categoryId.isEmpty) {
          return '((guild.channelCount|channelList[all;__default__;].count))';
        }
        return '((channelList[$categoryId;__default__;].count))';
      case 'categorycount':
        return '((guild.categoryCount|channelList[all;__default__;].categoryCount))';
      case 'categorychannels':
        final categoryId = _stringifyArgument(node, 0).trim();
        if (categoryId.isEmpty) return '';
        final separator = node.arguments.length > 1
            ? _stringifyArgument(node, 1)
            : '__default__';
        return '((channelList[$categoryId;$separator;].names))';
      case 'guildid':
      case 'serverid':
        if (node.arguments.isNotEmpty) {
          final guildName = _stringifyArgument(node, 0).trim();
          if (guildName.isNotEmpty) {
            return '((guild[$guildName].id))';
          }
        }
        return _inlineRuntimeVariables[node.normalizedName];
      case 'servername':
      case 'servericon':
      case 'serverdescription':
      case 'serverowner':
      case 'serververificationlevel':
      case 'serververificationlvl':
      case 'serverfeatures':
      case 'servervanityurl':
      case 'serverbanner':
      case 'serversplash':
      case 'serverregion':
        if (node.arguments.isNotEmpty) {
          final guildId = _stringifyArgument(node, 0).trim();
          if (guildId.isNotEmpty) {
            final field = switch (node.normalizedName) {
              'servername' => 'name',
              'servericon' => 'icon',
              'serverdescription' => 'description',
              'serverowner' => 'ownerId',
              'serververificationlevel' ||
              'serververificationlvl' => 'verificationLevel',
              'serverfeatures' => 'features',
              'servervanityurl' => 'vanityUrlCode',
              'serverbanner' => 'banner',
              'serversplash' => 'splash',
              'serverregion' => 'region',
              _ => 'name',
            };
            return '((guild[$guildId].$field))';
          }
        }
        return _inlineRuntimeVariables[node.normalizedName];
      case 'roleid':
        final roleName = _stringifyArgument(node, 0).trim();
        if (roleName.isNotEmpty) {
          return '((role[$roleName].id))';
        }
        return '';
      case 'rolename':
        final roleId = _stringifyArgument(node, 0).trim();
        if (roleId.isNotEmpty) {
          return '((role[$roleId].name))';
        }
        return '';
      case 'roleinfo':
        final roleId = _stringifyArgument(node, 0).trim();
        final property = _stringifyArgument(node, 1).trim();
        if (roleId.isNotEmpty) {
          if (property.isNotEmpty) {
            return '((role[$roleId].$property))';
          }
          return '((role[$roleId].info))';
        }
        return '';
      case 'roleexists':
        final roleId = _stringifyArgument(node, 0).trim();
        if (roleId.isNotEmpty) {
          return '((role[$roleId].exists))';
        }
        return 'false';
      case 'roleperms':
        final roleId = _stringifyArgument(node, 0).trim();
        if (roleId.isNotEmpty) {
          return '((role[$roleId].permissions))';
        }
        return '';
      case 'roleposition':
        final roleId = _stringifyArgument(node, 0).trim();
        if (roleId.isNotEmpty) {
          return '((role[$roleId].position))';
        }
        return '';
      case 'getrolecolor':
        final roleId = _stringifyArgument(node, 0).trim();
        if (roleId.isNotEmpty) {
          return '((role[$roleId].color))';
        }
        return '';
      case 'getrole':
        final userId = node.arguments.isNotEmpty
            ? _stringifyArgument(node, 0).trim()
            : '((author.id))';
        final index = node.arguments.length > 1
            ? _stringifyArgument(node, 1).trim()
            : '1';
        final guildId = _stringifyArgument(node, 2).trim();
        return '((memberRoleAt[$userId;$index;$guildId].id))';
      case 'ishoisted':
        final roleId = _stringifyArgument(node, 0).trim();
        if (roleId.isNotEmpty) {
          return '((role[$roleId].hoist))';
        }
        return 'false';
      case 'ismentionable':
        final roleId = _stringifyArgument(node, 0).trim();
        if (roleId.isNotEmpty) {
          return '((role[$roleId].mentionable))';
        }
        return 'false';
      case 'findrole':
        final roleName = _stringifyArgument(node, 0).trim();
        if (roleName.isNotEmpty) {
          return '((role[$roleName].id))';
        }
        return '';
      case 'hasrole':
        final userId = _stringifyArgument(node, 0).trim();
        final roleId = _stringifyArgument(node, 1).trim();
        if (userId.isEmpty || roleId.isEmpty) return 'false';
        return '((bdfdHasRole[((member[$userId].roles));$roleId]))';
      case 'userroles':
        final rolesUserId = _stringifyArgument(node, 0).trim();
        if (rolesUserId.isEmpty) return '';
        return '((bdfdUserRoles[((member[$rolesUserId].roleNamesJson))]))';
      case 'userswithrole':
        final uwrRoleId = _stringifyArgument(node, 0).trim();
        if (uwrRoleId.isNotEmpty) {
          final separator = _stringifyArgument(node, 1);
          final guildId = _stringifyArgument(node, 2).trim();
          return '((roleMembers[$uwrRoleId;${separator.isEmpty ? '__default__' : separator};$guildId].list))';
        }
        return '';
      // Parametric user info lookups
      case 'useravatar':
        if (node.arguments.isNotEmpty) {
          final userId = _stringifyArgument(node, 0).trim();
          if (userId.isNotEmpty) {
            return '((user[$userId].avatar))';
          }
        }
        return _inlineRuntimeVariables['useravatar'];
      case 'userbanner':
        if (node.arguments.isNotEmpty) {
          final userId = _stringifyArgument(node, 0).trim();
          if (userId.isNotEmpty) {
            return '((user[$userId].banner))';
          }
        }
        return _inlineRuntimeVariables['userbanner'];
      case 'getuserstatus':
      case 'getcustomstatus':
      case 'isuserdmenabled':
      case 'userbadges':
      case 'hypesquad':
      case 'dmchannelid':
        final requestedUserId = _stringifyArgument(node, 0).trim();
        final targetUserId = requestedUserId.isEmpty
            ? '((author.id))'
            : requestedUserId;
        final property = switch (node.normalizedName) {
          'getuserstatus' => 'status',
          'getcustomstatus' => 'customStatus',
          'isuserdmenabled' => 'dmEnabled',
          'userbadges' => 'badges',
          'hypesquad' => 'hypesquad',
          _ => 'dmChannelId',
        };
        return '((user[$targetUserId].$property))';
      case 'userinfo':
        final requestedUserId = _stringifyArgument(node, 0).trim();
        final targetUserId = requestedUserId.isEmpty
            ? '((author.id))'
            : requestedUserId;
        final property = _stringifyArgument(node, 1).trim();
        if (property.isEmpty) return '((user[$targetUserId].info))';
        return '((user[$targetUserId].info_$property))';
      case 'userperms':
      case 'authorperms':
      case 'memberperms':
        final userId = node.arguments.isNotEmpty
            ? _stringifyArgument(node, 0).trim()
            : '';
        final returnAmount = node.arguments.length > 1
            ? _stringifyArgument(node, 1).trim()
            : '-1';
        final separator = node.arguments.length > 2
            ? _stringifyArgument(node, 2).trim()
            : ', ';
        final targetUserId = userId.isEmpty ? '((author.id))' : userId;
        return '((userperms[$targetUserId;$returnAmount;$separator;((member[$targetUserId].permissions))]))';
      case 'isbot':
        if (node.arguments.isNotEmpty) {
          final userId = _stringifyArgument(node, 0).trim();
          if (userId.isNotEmpty) {
            return '((user[$userId].isBot))';
          }
        }
        return _inlineRuntimeVariables['isbot'];
      // Mentioned helper with index
      case 'mentioned':
        final requestedIndex = _stringifyArgument(node, 0).trim();
        final requestedFallback = _stringifyArgument(node, 1).trim();
        if (_containsRuntimePlaceholder(requestedIndex) ||
            _containsRuntimePlaceholder(requestedFallback)) {
          return _buildRuntimeBracketExpression('bdfdmentionedusers', [
            requestedIndex,
            requestedFallback,
          ]);
        }
        var returnSelf = false;
        var index = 1;
        if (node.arguments.length >= 2) {
          final firstArg = _stringifyArgument(node, 0).trim();
          final parsedIndex = int.tryParse(firstArg);
          if (parsedIndex != null && parsedIndex > 0) {
            index = parsedIndex;
          }
          final secondArg = _stringifyArgument(node, 1).trim().toLowerCase();
          returnSelf =
              secondArg == 'yes' || secondArg == 'true' || secondArg == '1';
        } else if (node.arguments.length == 1) {
          final firstArg = _stringifyArgument(node, 0).trim();
          final parsedIndex = int.tryParse(firstArg);
          if (parsedIndex != null && parsedIndex > 0) {
            index = parsedIndex;
          } else if (firstArg.toLowerCase() == 'yes' ||
              firstArg.toLowerCase() == 'true' ||
              firstArg.toLowerCase() == '1') {
            returnSelf = true;
          }
        }
        final zeroIndex = index - 1;
        return returnSelf
            ? '((message.mentions[$zeroIndex]|author.id))'
            : '((message.mentions[$zeroIndex]))';
      // All mentions (comma-separated user IDs)
      case 'mentions':
        return '((message.mentions))';
      // Reactions
      case 'getreactions':
        final channelId = _stringifyArgument(node, 0).trim();
        final messageId = _stringifyArgument(node, 1).trim();
        final emoji = _stringifyArgument(node, 2).trim();
        return '((getReactions[$channelId;$messageId;$emoji]))';
      case 'userreacted':
        if (node.arguments.length >= 4) {
          final channelId = _stringifyArgument(node, 0).trim();
          final messageId = _stringifyArgument(node, 1).trim();
          final userId = _stringifyArgument(node, 2).trim();
          final emoji = _stringifyArgument(node, 3).trim();
          final targetUser = userId.isEmpty ? '((author.id))' : userId;
          return '((userReacted[$channelId;$messageId;$targetUser;$emoji]))';
        }
        if (node.arguments.length == 3) {
          final arg0 = _stringifyArgument(node, 0).trim();
          final arg1 = _stringifyArgument(node, 1).trim();
          final arg2 = _stringifyArgument(node, 2).trim();
          return '((userReacted[$arg0;$arg1;((author.id));$arg2]))';
        }
        if (node.arguments.length == 2) {
          final messageId = _stringifyArgument(node, 0).trim();
          final emoji = _stringifyArgument(node, 1).trim();
          return '((userReacted[((channel.id));$messageId;((author.id));$emoji]))';
        }
        final emoji = node.arguments.isNotEmpty
            ? _stringifyArgument(node, 0).trim()
            : '';
        return '((userReacted[((channel.id));((message.id));((author.id));$emoji]))';
      // Emoji info
      case 'customemoji':
        final emojiName = _stringifyArgument(node, 0).trim();
        if (emojiName.isNotEmpty) {
          return '((emoji[$emojiName]))';
        }
        return '';
      case 'emotecount':
      case 'emojicount':
        final emojiGuildId = node.arguments.isNotEmpty
            ? _stringifyArgument(node, 0).trim()
            : '';
        return '((emojiCount[${emojiGuildId.isEmpty ? '((guild.id))' : emojiGuildId}]))';
      case 'serveremojis':
        final serverEmojiGuildId = _stringifyArgument(node, 0).trim();
        final serverEmojiSeparator = _stringifyArgument(node, 1);
        if (serverEmojiGuildId.isEmpty) return '';
        return '((serverEmojis[$serverEmojiGuildId;$serverEmojiSeparator]))';
      case 'stickercount':
        if (node.arguments.isNotEmpty) {
          final guildId = _stringifyArgument(node, 0).trim();
          if (guildId.isNotEmpty) {
            return '((guild[$guildId].stickerCount))';
          }
        }
        return _inlineRuntimeVariables['stickercount'];
      case 'boostcount':
      case 'serverboostcount':
        if (node.arguments.isNotEmpty) {
          final guildId = _stringifyArgument(node, 0).trim();
          if (guildId.isNotEmpty) {
            return '((guild[$guildId].premiumSubscriptionCount))';
          }
        }
        return _inlineRuntimeVariables['boostcount'];
      case 'emojiexists':
        final emojiName = _stringifyArgument(node, 0).trim();
        if (emojiName.isNotEmpty) {
          return '((emoji[$emojiName].exists))';
        }
        return 'false';
      case 'emojiname':
        final emojiId = _stringifyArgument(node, 0).trim();
        if (emojiId.isNotEmpty) {
          return '((emoji[$emojiId].name))';
        }
        return '';
      case 'isemojianimated':
        final emojiId = _stringifyArgument(node, 0).trim();
        if (emojiId.isNotEmpty) {
          return '((emoji[$emojiId].animated))';
        }
        return 'false';
      // Webhook info
      case 'webhookavatarurl':
        return '((webhook.avatarURL))';
      case 'webhookcolor':
        return '((webhook.color))';
      case 'webhookdescription':
        return '((webhook.description))';
      case 'webhookfooter':
        return '((webhook.footer))';
      case 'webhooktitle':
        return '((webhook.title))';
      case 'webhookusername':
        return '((webhook.username))';
      case 'webhookcontent':
        return '((webhook.content))';
      // Ticket
      case 'isticket':
        return '((channel.isTicket))';
      // getMessage
      case 'getmessage':
        return _inlineGetMessage(node);
      // $c - comment function, returns empty
      case 'url':
        if (node.arguments.isEmpty) {
          return _inlineRuntimeVariables['url'];
        }
        final urlMode = _stringifyArgument(node, 0).trim().toLowerCase();
        final urlText = _stringifyArgument(node, 1);
        if (_containsRuntimePlaceholder(urlText) ||
            _containsRuntimePlaceholder(urlMode)) {
          return _buildRuntimeBracketExpression('url', <String>[
            urlMode,
            urlText,
          ]);
        }
        try {
          if (urlMode == 'encode') {
            return Uri.encodeQueryComponent(urlText);
          } else if (urlMode == 'decode') {
            return Uri.decodeQueryComponent(urlText);
          }
        } catch (_) {
          return urlText;
        }
        return urlText;
      case 'c':
        return '';
      default:
        break;
    }

    final placeholder = _inlineRuntimePlaceholder(node);
    if (placeholder != null) {
      return placeholder;
    }

    switch (node.normalizedName) {
      // ── User-defined functions ──
      case 'funcarg':
        final paramName = _stringifyArgument(node, 0).trim().toLowerCase();
        return _funcArgScope[paramName] ?? '';
      case 'funcreturn':
        _funcReturnValue = _stringifyArgument(node, 0);
        return '';
      case 'funccall':
        return _expandUserFunction(node);
      // JSON functions
      case 'json':
        return _jsonGet(node);
      case 'jsonvalue':
        // Inside a $jsonForEach block, the runtime loop variable check at the
        // top of this function already handles $jsonValue[] (empty brackets).
        // Here we handle $jsonValue[path] used outside jsonForEach — it reads
        // from the JSON context just like $json[path].
        if (_runtimeLoopVarNames != null &&
            _runtimeLoopVarNames!.contains('jsonvalue') &&
            _loopDepth > 0) {
          return '((_loop.var.jsonvalue))';
        }
        return _jsonGet(node);
      case 'jsonkey':
        // $jsonKey is only meaningful inside $jsonForEach. Outside, return ''.
        if (_runtimeLoopVarNames != null &&
            _runtimeLoopVarNames!.contains('jsonkey') &&
            _loopDepth > 0) {
          return '((_loop.var.jsonkey))';
        }
        return '';
      case 'jsonindex':
        if (_runtimeLoopVarNames != null &&
            _runtimeLoopVarNames!.contains('jsonindex') &&
            _loopDepth > 0) {
          return '((_loop.var.jsonindex))';
        }
        return '';
      case 'jsonexists':
        return _jsonExists(node);
      case 'jsonstringify':
        return _jsonStringify();
      case 'jsonpretty':
        return _jsonPretty(node);
      case 'jsonarraycount':
        return _jsonArrayCount(node);
      case 'jsonarrayindex':
        return _jsonArrayIndex(node);
      case 'jsonjoinarray':
        return _jsonJoinArray(node);
      case 'jsonkeys':
        return _jsonKeys(node);
      case 'jsonarraypop':
        return _jsonArrayPop(node);
      case 'jsonarrayshift':
        return _jsonArrayShift(node);
      // HTTP results
      case 'httpstatus':
        return _latestHttpStatusPlaceholder(node);
      case 'httpresult':
        return _latestHttpResultPlaceholder(node);
      // Variable getters
      case 'getuservar':
        final gvVarName = _stringifyArgument(node, 0);
        final gvUserId = node.arguments.length > 1
            ? _stringifyArgument(node, 1).trim()
            : '';
        final gvGuildId = node.arguments.length > 2
            ? _stringifyArgument(node, 2).trim()
            : '';

        if (gvGuildId.isNotEmpty) {
          final contextId = gvUserId.isEmpty
              ? '$gvGuildId:((author.id))'
              : '$gvGuildId:$gvUserId';
          return _scopedVariablePlaceholder(
            'guildMember',
            gvVarName,
            contextId,
          );
        }
        return _scopedVariablePlaceholder('user', gvVarName, gvUserId);
      case 'getservervar':
      case 'getguildvar':
        final gsvVarName = _stringifyArgument(node, 0);
        final gsvGuildId = node.arguments.length > 1
            ? _stringifyArgument(node, 1).trim()
            : '';
        return _scopedVariablePlaceholder('guild', gsvVarName, gsvGuildId);
      case 'getchannelvar':
        final gcvVarName = _stringifyArgument(node, 0);
        final gcvChannelId = node.arguments.length > 1
            ? _stringifyArgument(node, 1).trim()
            : '';
        return _scopedVariablePlaceholder('channel', gcvVarName, gcvChannelId);
      case 'getmembervar':
      case 'getguildmembervar':
        final gmvVarName = _stringifyArgument(node, 0);
        final gmvUserId = node.arguments.length > 1
            ? _stringifyArgument(node, 1).trim()
            : '';
        final gmvGuildId = node.arguments.length > 2
            ? _stringifyArgument(node, 2).trim()
            : '';

        final guildPart = gmvGuildId.isNotEmpty ? gmvGuildId : '((guild.id))';
        final userPart = gmvUserId.isNotEmpty ? gmvUserId : '((author.id))';
        final contextId = '$guildPart:$userPart';
        return _scopedVariablePlaceholder('guildMember', gmvVarName, contextId);
      case 'getmessagevar':
        final gmvVarName = _stringifyArgument(node, 0);
        final gmvMessageId = node.arguments.length > 1
            ? _stringifyArgument(node, 1).trim()
            : '';
        return _scopedVariablePlaceholder('message', gmvVarName, gmvMessageId);
      case 'getvar':
        // BDFD wiki: $getVar[Variable name;(User ID)]
        final gvVarName = _stringifyArgument(node, 0);
        final gvUserId = node.arguments.length > 1
            ? _stringifyArgument(node, 1).trim()
            : '';
        if (gvUserId.isNotEmpty) {
          return _scopedVariablePlaceholder('user', gvVarName, gvUserId);
        }
        // Global variable lookup — uses store.getGlobalVariable via
        // ((global.<key>)) placeholder, injected by injectGlobalRuntimeVariables.
        return '((global.${gvVarName.trim()}))';
      case 'var':
        if (node.arguments.length >= 2) {
          return null;
        }
        return _scopedVariablePlaceholder('temp', _stringifyArgument(node, 0));
      case 'varexists':
        final key = _stringifyArgument(node, 0).trim();
        if (key.isNotEmpty) {
          return _buildRuntimeBracketExpression('varExists', [key]);
        }
        return 'false';
      case 'varexisterror':
        return '';
      case 'getleaderboardposition':
        if (node.arguments.isNotEmpty) {
          final varName = _stringifyArgument(node, 0).trim();
          final userId = node.arguments.length > 1
              ? _stringifyArgument(node, 1).trim()
              : '';
          final sort = node.arguments.length > 2
              ? _stringifyArgument(node, 2).trim()
              : '';
          final targetUser = userId.isEmpty ? '((author.id))' : userId;
          final targetSort = sort.isEmpty ? 'desc' : sort;
          return '((leaderboardPosition[$varName;$targetUser;$targetSort]))';
        }
        return '((leaderboard.position))';
      case 'getleaderboardvalue':
        if (node.arguments.isNotEmpty) {
          final varName = _stringifyArgument(node, 0).trim();
          final pos = node.arguments.length > 1
              ? _stringifyArgument(node, 1).trim()
              : '1';
          final sort = node.arguments.length > 2
              ? _stringifyArgument(node, 2).trim()
              : '';
          final targetSort = sort.isEmpty ? 'desc' : sort;
          return '((leaderboardValue[$varName;$pos;$targetSort]))';
        }
        return '((leaderboard.value))';
      case 'globaluserleaderboard':
        final guVarName = _stringifyArgument(node, 0).trim();
        final guSort = _stringifyArgument(node, 1).trim();
        return '((globalUserLeaderboard[$guVarName${guSort.isNotEmpty ? ';$guSort' : ''}]))';
      case 'serverleaderboard':
        final slVarName = _stringifyArgument(node, 0).trim();
        final slSort = _stringifyArgument(node, 1).trim();
        return '((serverLeaderboard[$slVarName${slSort.isNotEmpty ? ';$slSort' : ''}]))';
      case 'userleaderboard':
        final ulVarName = _stringifyArgument(node, 0).trim();
        final ulSort = _stringifyArgument(node, 1).trim();
        return '((userLeaderboard[$ulVarName${ulSort.isNotEmpty ? ';$ulSort' : ''}]))';
      case 'getcooldown':
        final cooldownType = _stringifyArgument(node, 0).trim();
        if (cooldownType.isNotEmpty) {
          return '((cooldown[$cooldownType].remaining))';
        }
        return '((cooldown.remaining))';
      // Workflow response
      case 'workflowresponse':
        return _latestWorkflowResponsePlaceholder(node);
      // Text manipulation (compile-time)
      case 'replacetext':
        return _inlineReplaceText(node);

      case 'tolowercase':
        final lowerValue = _stringifyArgument(node, 0);
        if (_containsRuntimePlaceholder(lowerValue)) {
          return _buildRuntimeBracketExpression('tolowercase', <String>[
            lowerValue,
          ]);
        }
        return lowerValue.toLowerCase();
      case 'touppercase':
        final upperValue = _stringifyArgument(node, 0);
        if (_containsRuntimePlaceholder(upperValue)) {
          return _buildRuntimeBracketExpression('touppercase', <String>[
            upperValue,
          ]);
        }
        return upperValue.toUpperCase();
      case 'totitlecase':
        final titleValue = _stringifyArgument(node, 0);
        if (_containsRuntimePlaceholder(titleValue)) {
          return _buildRuntimeBracketExpression('totitlecase', <String>[
            titleValue,
          ]);
        }
        return _inlineTitleCase(titleValue);
      case 'charcount':
        final charCountValue = _stringifyArgument(node, 0);
        if (_containsRuntimePlaceholder(charCountValue)) {
          return _buildRuntimeBracketExpression('charcount', <String>[
            charCountValue,
          ]);
        }
        return charCountValue.length.toString();
      case 'bytecount':
        final byteCountValue = _stringifyArgument(node, 0);
        if (_containsRuntimePlaceholder(byteCountValue)) {
          return _buildRuntimeBracketExpression('bytecount', <String>[
            byteCountValue,
          ]);
        }
        return utf8.encode(byteCountValue).length.toString();
      case 'linescount':
        final text = _stringifyArgument(node, 0);
        if (_containsRuntimePlaceholder(text)) {
          return _buildRuntimeBracketExpression('linescount', <String>[text]);
        }
        return text.isEmpty ? '0' : text.split('\n').length.toString();
      case 'croptext':
        final cropText = _stringifyArgument(node, 0);
        final cropLength = _stringifyArgument(node, 1);
        final cropSuffix = _stringifyArgument(node, 2);
        if (_containsRuntimePlaceholder(cropText) ||
            _containsRuntimePlaceholder(cropLength) ||
            _containsRuntimePlaceholder(cropSuffix)) {
          return _buildRuntimeBracketExpression('croptext', <String>[
            cropText,
            cropLength,
            cropSuffix,
          ]);
        }
        return _inlineCropText(node);
      case 'trimcontent':
        final trimContentValue = _stringifyArgument(node, 0);
        if (_containsRuntimePlaceholder(trimContentValue)) {
          return _buildRuntimeBracketExpression('trimcontent', <String>[
            trimContentValue,
          ]);
        }
        return trimContentValue.trim();
      case 'trimspace':
        final trimSpaceValue = _stringifyArgument(node, 0);
        if (_containsRuntimePlaceholder(trimSpaceValue)) {
          return _buildRuntimeBracketExpression('trimspace', <String>[
            trimSpaceValue,
          ]);
        }
        return trimSpaceValue.trim();
      case 'unescape':
        return _stringifyArgument(node, 0);
      case 'repeatmessage':
        return _inlineRepeatMessage(node);
      case 'removecontains':
        return _inlineRemoveContains(node);
      case 'numberseparator':
        return _inlineNumberSeparator(node);
      case 'splittext':
        return _inlineSplitText(node);
      case 'editsplittext':
        return _inlineEditSplitText(node);
      case 'gettextsplitindex':
        return _inlineGetTextSplitIndex(node);
      case 'gettextsplitlength':
        return _inlineTextSplitRead(node, 'length');
      case 'joinsplittext':
        return _inlineJoinSplitText(node);
      case 'removesplittextelement':
        return _inlineRemoveSplitTextElement(node);
      // Math functions (compile-time)
      case 'calculate':
        return _inlineCalculate(node);
      case 'ceil':
        return _inlineMathUnary(node, (v) => v.ceil());
      case 'floor':
        return _inlineMathUnary(node, (v) => v.floor());
      case 'round':
        return _inlineMathUnary(node, (v) => v.round());
      case 'sqrt':
        return _inlineMathUnaryDouble(node, math.sqrt);
      case 'max':
        return _inlineMathBinary(node, math.max);
      case 'min':
        return _inlineMathBinary(node, math.min);
      case 'modulo':
        return _inlineMathBinaryOp(node, (a, b) => b != 0 ? a % b : 0);
      case 'multi':
        return _inlineMathBinaryOp(node, (a, b) => a * b);
      case 'divide':
        return _inlineMathBinaryOp(node, (a, b) => b != 0 ? a / b : 0);
      case 'sub':
        return _inlineMathBinaryOp(node, (a, b) => a - b);
      case 'sum':
        return _inlineSum(node);
      case 'sort':
        return _inlineSort(node);
      // Boolean check functions (compile-time)
      case 'isboolean':
        return _inlineIsBoolean(node);
      case 'isinteger':
        return _inlineIsInteger(node);
      case 'isnumber':
        return _inlineIsNumber(node);
      case 'isvalidhex':
        return _inlineIsValidHex(node);
      case 'checkcondition':
        return _inlineCheckCondition(node);
      case 'checkcontains':
        return _inlineCheckContains(node);
      // Random functions (compile-time)
      case 'random':
        return _inlineRandom(node);
      case 'randomstring':
        return _inlineRandomString(node);
      case 'randomtext':
        return _inlineRandomText(node);
      // Date/Time functions (runtime dynamic)
      case 'date':
        return '((date))';
      case 'day':
        return '((day))';
      case 'hour':
        return '((hour))';
      case 'minute':
        return '((minute))';
      case 'month':
        return '((month))';
      case 'second':
        return '((second))';
      case 'year':
        return '((year))';
      case 'time':
        return '((time))';
      case 'gettimestamp':
        return '((getTimestamp))';
      case 'gettimestampms':
        return '((getTimestampMs))';
      // Music info (inline — return text)
      case 'lavalinkplaying':
        return '((lavalink.title))';
      case 'lavalinkauthor':
        return '((lavalink.author))';
      case 'lavalinkduration':
        return '((lavalink.duration))';
      case 'lavalinkposition':
        return '((lavalink.position))';
      case 'lavalinkqueuesize':
        return '((lavalink.queueSize))';
      case 'lavalinkvolume':
        return '((lavalink.volume))';
      case 'lavalinkispaused':
        return '((lavalink.isPaused))';
      case 'lavalinkislooping':
        return '((lavalink.isLooping))';
      // Misc inline
      case 'hostingexpiretime':
        return '((hosting.expireTime))';
      case 'premiumexpiretime':
        return '((premium.expireTime))';
      case 'randomcategoryid':
        return '((random.categoryId))';
      case 'randomchannelid':
        return '((random.channelId))';
      case 'randomguildid':
        return '((random.guildId))';
      case 'randommention':
        return '((random.mention))';
      case 'randomroleid':
        return '((random.roleId))';
      case 'randomuser':
        return '((random.user))';
      case 'randomuserid':
        return '((random.userId))';
      // Parameterized inline functions (wiki requires arguments)
      case 'getbanreason':
        // BDFD wiki: $getBanReason[User ID;(Guild ID)]
        final brUserId = _stringifyArgument(node, 0).trim();
        if (brUserId.isNotEmpty) {
          final brGuildId = _stringifyArgument(node, 1).trim();
          if (brGuildId.isNotEmpty) {
            return '((ban.reason[$brUserId;$brGuildId]))';
          }
          return '((ban.reason[$brUserId]))';
        }
        return _inlineRuntimeVariables['getbanreason'];
      case 'isbanned':
        // BDFD wiki: $isBanned[User ID]
        final ibUserId = _stringifyArgument(node, 0).trim();
        if (ibUserId.isNotEmpty) {
          return '((member[$ibUserId].isBanned))';
        }
        return _inlineRuntimeVariables['isbanned'];
      case 'istimedout':
        // BDFD wiki: $isTimedOut[User ID]
        final itUserId = _stringifyArgument(node, 0).trim();
        if (itUserId.isNotEmpty) {
          return '((member[$itUserId].isTimedOut))';
        }
        return _inlineRuntimeVariables['istimedout'];
      case 'isnsfw':
        // BDFD wiki: $isNSFW[Channel ID]
        final nsfwChannelId = _stringifyArgument(node, 0).trim();
        if (nsfwChannelId.isNotEmpty) {
          return '((channel[$nsfwChannelId].nsfw))';
        }
        return _inlineRuntimeVariables['isnsfw'];
      case 'ismentioned':
        final imUserId = _stringifyArgument(node, 0).trim();
        if (imUserId.isNotEmpty) {
          return '((bdfdIsMentioned[$imUserId]))';
        }
        return 'false';
      case 'ismessageedited':
        // BDFD wiki: $isMessageEdited[Channel ID;Message ID]
        final meChannelId = _stringifyArgument(node, 0).trim();
        final meMessageId = _stringifyArgument(node, 1).trim();
        if (meChannelId.isNotEmpty && meMessageId.isNotEmpty) {
          return '((message[$meChannelId;$meMessageId].isEdited))';
        }
        return _inlineRuntimeVariables['ismessageedited'];
      case 'getattachments':
        final messageId = _stringifyArgument(node, 0).trim();
        if (messageId.isNotEmpty) {
          return '((message[$messageId].attachments))';
        }
        return '((message.attachments))';
      case 'getembeddata':
        final edChannelId = _stringifyArgument(node, 0).trim();
        final edMessageId = _stringifyArgument(node, 1).trim();
        final edIndex = _stringifyArgument(node, 2).trim();
        final edProperty = _stringifyArgument(node, 3).trim().toLowerCase();
        if (edChannelId.isNotEmpty &&
            edMessageId.isNotEmpty &&
            edIndex.isNotEmpty &&
            edProperty.isNotEmpty) {
          return '((getEmbedData[$edChannelId;$edMessageId;$edIndex;$edProperty]))';
        }
        return '';
      case 'and':
        final andArgs = <String>[];
        for (var i = 0; i < node.arguments.length; i++) {
          andArgs.add(_stringifyArgument(node, i));
        }
        return _buildRuntimeBracketExpression('and', andArgs);
      case 'or':
        final orArgs = <String>[];
        for (var i = 0; i < node.arguments.length; i++) {
          orArgs.add(_stringifyArgument(node, i));
        }
        return _buildRuntimeBracketExpression('or', orArgs);
      case 'listvar':
        final listvarSep = node.arguments.isNotEmpty
            ? _stringifyArgument(node, 0)
            : ', ';
        return _buildRuntimeBracketExpression('listvar', <String>[
          listvarSep.contains('((') ? listvarSep : jsonEncode(listvarSep),
        ]);
      case 'variablescount':
        final vcType = node.arguments.isNotEmpty
            ? _stringifyArgument(node, 0)
            : '';
        return _buildRuntimeBracketExpression('variablescount', <String>[
          vcType,
        ]);
      case 'error':
        // BDFD wiki: $error[Type] — returns specific error metadata.
        if (node.arguments.isNotEmpty) {
          final errorType = _stringifyArgument(node, 0).trim().toLowerCase();
          switch (errorType) {
            case 'message':
              return '((error.message))';
            case 'command':
              return '((error.command))';
            case 'source':
              return '((error.source))';
            case 'row':
              return '((error.row))';
            case 'column':
              return '((error.column))';
          }
        }
        // $error without args or with unknown type falls back to message.
        return '((error.message))';
      default:
        return _inlineRuntimePlaceholder(node);
    }
  }

  /// Expands a user-defined function call ($funcCall[name;args...]).
  /// The function body is processed with parameters substituted, and the
  /// return value (from $funcReturn or the body text content) is returned.
  String _expandUserFunction(BdfdFunctionCallAst node) {
    final funcName = _stringifyArgument(node, 0).trim().toLowerCase();
    final funcDef = _userFunctions[funcName];
    if (funcDef == null) {
      _diagnostics.add(
        BdfdTranspileDiagnostic(
          message: '${r'$funcCall'} references undefined function "$funcName".',
          start: node.start,
          end: node.end,
          functionName: node.name,
        ),
      );
      return '';
    }

    // Prevent infinite recursion.
    if (_funcCallDepth >= 10) {
      _diagnostics.add(
        BdfdTranspileDiagnostic(
          message:
              'Function call depth limit exceeded for "$funcName" (possible recursion).',
          severity: BdfdTranspileDiagnosticSeverity.warning,
          start: node.start,
          end: node.end,
          functionName: node.name,
        ),
      );
      return '';
    }

    // Save and set up parameter scope.
    final previousArgScope = Map<String, String>.from(_funcArgScope);
    final previousReturnValue = _funcReturnValue;

    // Compute argument values in the CALLING scope (where $funcArg from
    // the outer context is still available) BEFORE switching to the
    // function's own scope.
    final argValues = <String>[];
    for (var i = 0; i < funcDef.paramNames.length; i++) {
      final argValue = i + 1 < node.arguments.length
          ? _stringifyArgument(node, i + 1)
          : '';
      argValues.add(argValue);
    }

    _funcArgScope = <String, String>{};
    for (var i = 0; i < funcDef.paramNames.length; i++) {
      _funcArgScope[funcDef.paramNames[i]] = argValues[i];
    }

    _funcReturnValue = null;
    _funcCallDepth += 1;

    // Process the body: stringify all nodes (text + inline functions).
    // The text content becomes the default return value.
    final textContent = _stringifyNodes(funcDef.bodyNodes);

    _funcCallDepth -= 1;

    // If $funcReturn was called, use that; otherwise use text content.
    final result = _funcReturnValue ?? textContent;

    // Restore scope.
    _funcArgScope = previousArgScope;
    _funcReturnValue = previousReturnValue;

    return result;
  }

  String? _inlineRuntimePlaceholder(BdfdFunctionCallAst node) {
    switch (node.normalizedName) {
      case 'isbanned':
        if (node.arguments.isNotEmpty) {
          return '((member[${_stringifyArgument(node, 0).trim()}].isBanned))';
        }
      case 'istimedout':
        if (node.arguments.isNotEmpty) {
          return '((member[${_stringifyArgument(node, 0).trim()}].isTimedOut))';
        }
      case 'getbanreason':
        if (node.arguments.isNotEmpty) {
          final userId = _stringifyArgument(node, 0).trim();
          final guildId = node.arguments.length > 1
              ? _stringifyArgument(node, 1).trim()
              : '';
          return '((ban.reason[$userId${guildId.isEmpty ? '' : ';$guildId'}]))';
        }
      case 'getserverinvite':
        if (node.arguments.isNotEmpty) {
          final guildId = _stringifyArgument(node, 0).trim();
          if (guildId.isNotEmpty) {
            return '((guild[$guildId].invite))';
          }
        }
        return '((guild.invite))';
      case 'getinviteinfo':
        final inviteCode = _stringifyArgument(node, 0).trim();
        final inviteProp = _stringifyArgument(node, 1).trim();
        if (inviteCode.isNotEmpty) {
          if (inviteProp.isNotEmpty) {
            return '((invite[$inviteCode].$inviteProp))';
          }
          return '((invite[$inviteCode].info))';
        }
        return '((invite.info))';
      case 'serverinfo':
        final arg0 = _stringifyArgument(node, 0).trim();
        final arg1 = _stringifyArgument(node, 1).trim();
        if (arg1.isNotEmpty) {
          return '((guild[$arg0].info_$arg1))';
        }
        if (arg0.isNotEmpty) {
          if (int.tryParse(arg0) != null) {
            return '((guild[$arg0].info))';
          }
          return '((guild.info_$arg0))';
        }
        return '((guild.info))';
    }
    return _inlineRuntimeVariables[node.normalizedName];
  }

  bool _isInlineOnlyNode(BdfdFunctionCallAst node) {
    if (node.normalizedName == 'var' && node.arguments.length >= 2) {
      return false;
    }
    return _isInlineOnlyFunction(node.normalizedName);
  }

  bool _isInlineOnlyFunction(String normalizedName) {
    if (_loopDepth > 0 && _loopVariables.containsKey(normalizedName)) {
      return true;
    }
    if (_loopDepth > 0 && _loopStringVariables.containsKey(normalizedName)) {
      return true;
    }
    if (_runtimeLoopVarNames != null &&
        _runtimeLoopVarNames!.contains(normalizedName)) {
      return true;
    }
    switch (normalizedName) {
      case 'json':
      case 'jsonvalue':
      case 'jsonkey':
      case 'jsonindex':
      case 'jsonexists':
      case 'jsonstringify':
      case 'jsonpretty':
      case 'jsonarraycount':
      case 'jsonarrayindex':
      case 'jsonjoinarray':
      case 'jsonkeys':
      case 'jsonarraypop':
      case 'jsonarrayshift':
      case 'addemoji':
      case 'createchannel':
      case 'newticket':
      case 'webhookcreate':
      case 'startthread':
      case 'editthread':
      case 'threadaddmember':
      case 'threadremovemember':
      case 'checkuserperms':
      case 'checkusersperms':
      case 'hasperms':
      case 'message':
      case 'args':
      case 'i':
      case 'loopindex':
      case 'loopiteration':
      case 'loopcount':
      case 'mentionedchannels':
      case 'httpstatus':
      case 'httpresult':
      case 'getuservar':
      case 'getservervar':
      case 'getguildvar':
      case 'getchannelvar':
      case 'getmembervar':
      case 'getguildmembervar':
      case 'getmessagevar':
      case 'getvar':
      case 'var':
      case 'varexists':
      case 'varexisterror':
      case 'workflowresponse':
      case 'getleaderboardposition':
      case 'getleaderboardvalue':
      case 'getcooldown':
      // User-defined function helpers
      case 'funcarg':
      case 'funcreturn':
      case 'funccall':
      // Text manipulation
      case 'replacetext':
      case 'url':
      case 'tolowercase':
      case 'touppercase':
      case 'totitlecase':
      case 'charcount':
      case 'bytecount':
      case 'linescount':
      case 'croptext':
      case 'trimcontent':
      case 'trimspace':
      case 'unescape':
      case 'repeatmessage':
      case 'removecontains':
      case 'numberseparator':
      case 'splittext':
      case 'editsplittext':
      case 'gettextsplitindex':
      case 'gettextsplitlength':
      case 'joinsplittext':
      case 'removesplittextelement':
      // Math
      case 'calculate':
      case 'ceil':
      case 'floor':
      case 'round':
      case 'sqrt':
      case 'max':
      case 'min':
      case 'modulo':
      case 'multi':
      case 'divide':
      case 'sub':
      case 'sum':
      case 'sort':
      // Boolean checks
      case 'isboolean':
      case 'isinteger':
      case 'isnumber':
      case 'isvalidhex':
      case 'checkcondition':
      case 'checkcontains':
      // Random
      case 'random':
      case 'randomstring':
      case 'randomtext':
      // Date/Time
      case 'date':
      case 'day':
      case 'hour':
      case 'minute':
      case 'month':
      case 'second':
      case 'year':
      case 'time':
      case 'gettimestamp':
      case 'gettimestampms':
      // Parametric lookups
      case 'channelid':
      case 'channelidfromname':
      case 'and':
      case 'or':
      case 'listvar':
      case 'variablescount':
      case 'guildid':
      case 'roleid':
      case 'rolename':
      case 'roleinfo':
      case 'roleexists':
      case 'roleperms':
      case 'roleposition':
      case 'getrole':
      case 'getrolecolor':
      case 'isbot':
      case 'ishoisted':
      case 'ismentionable':
      case 'findrole':
      case 'hasrole':
      case 'userswithrole':
      case 'useravatar':
      case 'userbanner':
      case 'mentioned':
      case 'mentions':
      case 'getreactions':
      case 'userreacted':
      case 'customemoji':
      case 'emotecount':
      case 'emojicount':
      case 'emojiexists':
      case 'emojiname':
      case 'isemojianimated':
      case 'webhookavatarurl':
      case 'webhookcolor':
      case 'webhookdescription':
      case 'webhookfooter':
      case 'webhooktitle':
      case 'webhookusername':
      case 'webhookcontent':
      case 'isticket':
      case 'getmessage':
      case 'c':
      case 'globaluserleaderboard':
      case 'serverleaderboard':
      case 'userleaderboard':
      case 'getserverinvite':
      case 'getinviteinfo':
      case 'hostingexpiretime':
      case 'premiumexpiretime':
      case 'randomcategoryid':
      case 'randomchannelid':
      case 'randomguildid':
      case 'randommention':
      case 'randomroleid':
      case 'randomuser':
      case 'randomuserid':
        return true;
      default:
        return _inlineRuntimeVariables.containsKey(normalizedName);
    }
  }

  bool _requiresPendingResponseFlush(String normalizedName) {
    switch (normalizedName) {
      // ── Message sending / channel switching ──
      case 'sendmessage':
      case 'channelsendmessage':
      case 'reply':
      case 'dm':
      case 'sendembedmessage':
      case 'replyin':
      case 'usechannel':
      // ── Guards ──
      case 'onlyif':
      case 'onlyforusers':
      case 'onlyforchannels':
      case 'onlyforroles':
      case 'onlyforids':
      case 'onlyforroleids':
      case 'onlyforservers':
      case 'onlyforcategories':
      case 'ignorechannels':
      case 'onlynsfw':
      case 'onlyadmin':
      case 'onlyperms':
      case 'onlybotperms':
      case 'onlybotchannelperms':
      case 'checkuserperms':
      case 'checkusersperms':
      case 'hasperms':
      case 'onlyifmessagecontains':
      case 'argscheck':
      // ── Control flow ──
      case 'if':
      case 'stop':
      case 'enabled':
      case 'skipactions':
      case 'jumptoaction':
      // ── Threads (change message target) ──
      case 'startthread':
      case 'editthread':
      case 'threadaddmember':
      case 'threadremovemember':
      // ── Webhook / interaction output ──
      case 'webhooksend':
      case 'newmodal':
      case 'defer':
      // ── Cooldown (guard-like, stops execution) ──
      case 'cooldown':
      case 'globalcooldown':
      case 'servercooldown':
      // ── Meta (foreign script execution; pending content must go first) ──
      case 'eval':
      case 'debug':
      case 'callworkflow':
        return true;
      default:
        return false;
    }
  }

  List<Action> _drainDeferredInlineActions() {
    if (_deferredInlineActions.isEmpty) {
      return const <Action>[];
    }
    final drained = List<Action>.from(_deferredInlineActions);
    _deferredInlineActions.clear();
    return drained;
  }

  void _enqueuePendingConditionAction(Action action) {
    if (_conditionActionStack.isEmpty) {
      _deferredInlineActions.add(action);
      return;
    }
    _conditionActionStack.last.add(action);
  }

  List<Action> _drainPendingConditionActions() {
    if (_conditionActionStack.isEmpty || _conditionActionStack.last.isEmpty) {
      return const <Action>[];
    }
    final drained = List<Action>.from(_conditionActionStack.last);
    _conditionActionStack.last.clear();
    return drained;
  }
}
