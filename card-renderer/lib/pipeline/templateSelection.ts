import { access } from 'node:fs/promises';
import path from 'node:path';
import { loadCachedLayout } from './compositionAssetCache';
import type { CatRarity, SelectedTemplate } from './types';

const templatesRoot = path.join(process.cwd(), 'assets/cards/templates');
const legacyTemplatePath = path.join(process.cwd(), 'public/cards/catdex_template_v2.png');

async function exists(filePath: string): Promise<boolean> {
  try {
    await access(filePath);
    return true;
  } catch {
    return false;
  }
}

export async function selectTemplate(
  rarity: CatRarity,
  eventKey?: string,
  eventTemplateKey?: string,
): Promise<SelectedTemplate> {
  console.log('CATDEX_TEMPLATE_RARITY_REQUESTED', rarity);
  console.log('CATDEX_TEMPLATE_EVENT_KEY', eventKey ?? '-');

  if (eventKey && eventTemplateKey) {
    const selectedEventTemplateKey = `events/${eventKey}/${eventTemplateKey}`;
    const eventPaths = templatePaths(selectedEventTemplateKey, true);
    console.log('CATDEX_TEMPLATE_TRY_EVENT_PATH', eventPaths.templatePath);
    if (await exists(eventPaths.templatePath) && (await exists(eventPaths.layoutPath))) {
      console.log('CATDEX_TEMPLATE_FALLBACK_USED', false);
      return loadSelectedTemplate(selectedEventTemplateKey, eventPaths.templatePath, eventPaths.layoutPath);
    }
  } else {
    console.log('CATDEX_TEMPLATE_TRY_EVENT_PATH', '-');
  }

  const defaultTemplateKey = `default/${rarity}`;
  const defaultPaths = templatePaths(defaultTemplateKey);
  console.log('CATDEX_TEMPLATE_TRY_DEFAULT_PATH', defaultPaths.templatePath);
  if (await exists(defaultPaths.templatePath) && (await exists(defaultPaths.layoutPath))) {
    console.log('CATDEX_TEMPLATE_FALLBACK_USED', false);
    return loadSelectedTemplate(defaultTemplateKey, defaultPaths.templatePath, defaultPaths.layoutPath);
  }

  const commonTemplateKey = 'default/common';
  const commonPaths = templatePaths(commonTemplateKey);
  if (await exists(commonPaths.templatePath) && (await exists(commonPaths.layoutPath))) {
    console.log('CATDEX_TEMPLATE_FALLBACK_USED', true);
    return loadSelectedTemplate(commonTemplateKey, commonPaths.templatePath, commonPaths.layoutPath);
  }

  console.log('CATDEX_TEMPLATE_FALLBACK_USED', true);
  return loadSelectedTemplate('legacy/catdex_template_v2', legacyTemplatePath, commonPaths.layoutPath);
}

function templatePaths(templateKey: string, svgTemplate = false) {
  const templateDirectory = path.join(templatesRoot, templateKey);
  return {
    templatePath: path.join(
      templateDirectory,
      svgTemplate ? 'template.svg' : 'template.png',
    ),
    layoutPath: path.join(templateDirectory, 'layout.json'),
  };
}

async function loadSelectedTemplate(key: string, templatePath: string, layoutPath: string): Promise<SelectedTemplate> {
  const layout = await loadCachedLayout(key, layoutPath);
  console.log('CATDEX_TEMPLATE_SELECTED_KEY', key);
  console.log('CATDEX_TEMPLATE_SELECTED_PATH', templatePath);
  console.log('CATDEX_TEMPLATE_LAYOUT_PATH', layoutPath);

  return {
    key,
    templatePath,
    layoutPath,
    layout,
  };
}
